require "timeout"

module Turbine
  class Task
    class << self
      def current
        fiber = ::Fiber.current
        fiber.task if fiber.is_a?(Turbine::Fiber)
      end
    end

    def initialize(thread, &block)
      @thread = thread
      @block = block

      @value_mutex = Mutex.new
      @value_cond = ConditionVariable.new

      @called = false
      @value = nil
      @value_type = nil
    end

    attr_reader :thread

    def reactor
      thread.reactor
    end

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

    def error?
      @value_type == :error
    end

    def value?
      @value_type == :value
    end

    def done?
      value_type = @value_type
      value_type == :value || value_type == :error
    end

    private

    def set(type)
      @value_mutex.synchronize do
        if @value_type
          # this should never happen, because fibers cannot cross thread boundaries
          raise DoubleResultError, "a #{@value_type} value exist"
        end

        @value_type = type
        @value = yield
        @value_cond.broadcast

        @value
      end
    end
  end
end
