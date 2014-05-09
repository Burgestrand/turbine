module Turbine
  class Fiber < ::Fiber
    def initialize(task)
      @task = task
      super()
    end

    attr_reader :task
  end
end
