module Turbine
  module Refinements
    refine ConditionVariable do
      def wait_until(mutex, timeout = nil)
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
end
