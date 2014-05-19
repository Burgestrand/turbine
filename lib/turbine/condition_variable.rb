require "thread"
require "forwardable"

module Turbine
  class ConditionVariable
    extend Forwardable

    def initialize
      @condvar = ::ConditionVariable.new
    end

    def_delegators :@condvar, :wait, :signal, :broadcast

    def wait_until(mutex, timeout = nil)
      unless block_given?
        raise ArgumentError, "no block given"
      end

      if timeout
        finished = Time.now + timeout
        until yield
          timeout = finished - Time.now
          break unless timeout > 0
          wait(mutex, timeout)
        end
      else
        wait(mutex) until yield
      end

      return self
    end
  end
end
