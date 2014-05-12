require "timeout"

module Turbine
  class Task
    class << self
      # @return [Turbine::Fiber, nil] the fiber currently executing in the current thread
      def current
        fiber = ::Fiber.current
        fiber.task if fiber.is_a?(Turbine::Fiber)
      end
    end

    # Create a new task, assigned to run on the given thread.
    #
    # @param [Turbine::Thread] thread assigned to this task
    # @yield task body
    def initialize(thread, &block)
      @thread = thread
      @block = block

      @value_mutex = Mutex.new
      @value_cond = ConditionVariable.new

      @called = false
      @value = nil
      @value_type = nil
    end

    # @return [Turbine::Thread] thread assigned to this task
    attr_reader :thread

    # @return [Turbine::Reactor] reactor assigned to this task
    def reactor
      thread.reactor
    end

    # Retrieve the fiber powering this task.
    #
    # @return [Turbine::Fiber]
    # @raise [OwnershipError] if calling thread is not same as {#thread}
    def fiber
      if Thread.current != thread
        # this branch ensures thread-safety for the other branch
        raise OwnershipError, "#{Thread.current} != #{thread}"
      else
        @fiber ||= Turbine::Fiber.new(self) do |*args, &block|
          begin
            value = @block.call(*args, &block)
            set(:value) { value }
          rescue Exception => ex
            set(:error) { ex }
            raise ex
          end
        end
      end
    end

    # Retrieve or wait for the value the task will resolve into.
    #
    # Blocks if until a value is available, or until the timeout
    # is reached.
    #
    # @param [Integer, nil] timeout how long to wait for value before timing out
    # @yield if block given, yields instead of raising an error on timeout
    # @raise [TimeoutError] if waiting timeout was reached
    def value(timeout = nil)
      @value_mutex.synchronize do
        @value_cond.wait(@value_mutex, timeout) unless done?
      end

      if value?
        return @value
      elsif error?
        raise @value
      elsif block_given?
        yield
      else
        raise TimeoutError, "retrieving value timed out after #{timeout}s"
      end
    end

    # @return [Boolean] true if this task terminated with an error
    def error?
      @value_type == :error
    end

    # @return [Boolean] true if this task terminated with a value
    def value?
      @value_type == :value
    end

    # @return [Boolean] true if this task has finished executing
    def done?
      value_type = @value_type
      value_type == :value || value_type == :error
    end

    private

    def set(type)
      @value_mutex.synchronize do
        if @value_type
          # this should never happen, because fibers cannot cross thread boundaries
          raise Error, "a #{@value_type} value exist; this should never happen!"
        end

        @value_type = type
        @value = yield
        @value_cond.broadcast

        @value
      end
    end
  end
end
