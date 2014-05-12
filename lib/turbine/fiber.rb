require "fiber"

module Turbine
  class Fiber < ::Fiber
    def initialize(task)
      @task = task
      super()
    end

    # @return [Turbine::Task] the task assigned to this fiber
    attr_reader :task
  end
end
