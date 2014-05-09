module Turbine
  class Reactor < ::Thread
    class << self
      def current
        thread = Thread.current
        thread if thread.is_a?(Reactor)
      end
    end

    def initialize
      @queue = []
      @queue_mutex = Mutex.new
      @queue_cond = ConditionVariable.new

      super do
        begin
          loop do
            task = @queue_mutex.synchronize do
              break if @queue.nil?
              @queue_cond.wait(@queue_mutex) if @queue.empty?
              @queue.pop
            end

            begin
              task.fiber.resume
            rescue Exception => ex
              # TODO: should an error raised from the task crash the reactor?
            end
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

    attr_reader :error

    def crashed?
      !! error
    end

    # @yield
    # @return [Task]
    def spawn
      if Reactor.current == self
        yield
      else
        enqueue(Proc.new)
      end
    end

    # @return [Task]
    def shutdown
      cleanup = lambda { yield if block_given? }
      enqueue(work) { @queue = nil }
    end

    private

    def enqueue(callable)
      @queue_mutex.synchronize do
        if @queue
          task = Task.new(callable)
          @queue << task
          @queue_cond.broadcast
          yield task if block_given?
          task
        else
          raise TerminatingError, "reactor is terminating"
        end
      end
    end
  end
end
