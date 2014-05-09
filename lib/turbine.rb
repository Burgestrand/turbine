require "turbine/fiber"
require "turbine/task"
require "turbine/reactor"

module Turbine
  class Error < StandardError; end
  class TerminatingError < StandardError; end
  class OwnershipError < StandardError; end
  class DoubleResumeError < StandardError; end
end
