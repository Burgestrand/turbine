module Turbine
  class Reactor
    class << self
      # @return [Turbine::Reactor, nil] the reactor powering the current thread
      def current
        thread = ::Thread.current
        thread.reactor if thread.is_a?(Turbine::Thread)
      end
    end

    def initialize
      @queue = Turbine::FIFO.new

      @running = true
      @shutdown = false
      @shutdown_mutex = Mutex.new

      @thread = Turbine::Thread.new(self) do
        begin
          while @running
            task = @queue.dequeue
            task.fiber.resume
          end

          unless @queue.empty?
            raise Error, "tasks was queued after terminate, this should not happen!"
          end

          # Clean shutdown!
        rescue Exception => ex
          @error = ex
          raise ex
        end
      end
    end

    # @return [Turbine::Thread] thread powering the reactor
    attr_reader :thread

    # @return [Exception, nil] error that caused reactor to crash, if any
    attr_reader :error

    # @return [Boolean] true if reactor has crashed with an error
    def crashed?
      !! error
    end

    # @return [Boolean] true if the reactor is running
    def running?
      @thread.alive? and not @shutdown
    end

    # Spawn a task with the given block for later execution in the reactor.
    #
    # @param [Array] args arguments to pass to the block
    # @yield [*args] task body
    # @return [Turbine::Task]
    def spawn(*args)
      if Reactor.current == self
        raise Error, "cannot spawn task in current reactor"
      elsif block_given?
        enqueue(task { yield *args })
      else
        raise ArgumentError, "no block given"
      end
    end

    # Schedule a shutdown of the reactor after all enqueued tasks have finished.
    #
    # @param [Array] args arguments to pass to the block
    # @yield [*args] task body
    # @return [Turbine::Task]
    def shutdown(*args)
      cleanup = task do
        @running = false
        yield *args if block_given?
      end

      enqueue(cleanup) { @shutdown = true }
    end

    private

    def task
      Turbine::Task.new(@thread) do
        yield
      end
    end

    def enqueue(task)
      @shutdown_mutex.synchronize do
        if running?
          if @queue.enqueue(task)
            yield task if block_given?
            task
          else
            raise DoubleEnqueueError, "task #{task} is already queued"
          end
        else
          raise DeadReactorError, "reactor is terminated"
        end
      end
    end
  end
end
