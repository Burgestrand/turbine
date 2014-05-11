module Turbine
  class Reactor
    class << self
      def current
        thread = ::Thread.current
        thread.reactor if thread.is_a?(Turbine::Thread)
      end
    end

    def initialize
      @queue = []
      @queue_mutex = Mutex.new
      @queue_cond = ConditionVariable.new

      @running = true
      @shutdown = false
      @thread = Turbine::Thread.new(self) do
        begin
          while @running
            task = @queue_mutex.synchronize do
              @queue_cond.wait(@queue_mutex) if @queue.empty?
              @queue.shift
            end

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

    attr_reader :thread

    attr_reader :error

    def crashed?
      !! error
    end

    def alive?
      @thread.alive? and not @shutdown
    end

    # @yield
    # @return [Task]
    def spawn
      if Reactor.current == self
        raise Error, "cannot spawn task in current reactor"
      elsif block_given?
        enqueue(Proc.new)
      else
        raise ArgumentError, "no block given"
      end
    end

    # @return [Task]
    def shutdown
      cleanup = lambda do
        @running = false
        yield if block_given?
      end

      enqueue(cleanup) { @shutdown = true }
    end

    private

    def enqueue(callable)
      @queue_mutex.synchronize do
        if alive?
          task = Turbine::Task.new(@thread, &callable)
          @queue.push(task)
          @queue_cond.broadcast
          yield task if block_given?
          task
        else
          raise DeadReactorError, "reactor is terminated"
        end
      end
    end
  end
end
