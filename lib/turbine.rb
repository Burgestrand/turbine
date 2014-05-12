require "turbine/fiber"
require "turbine/thread"

require "turbine/fifo"
require "turbine/task"
require "turbine/reactor"

module Turbine
  class Error < StandardError; end
  class DeadReactorError < StandardError; end
  class DoubleEnqueueError < StandardError; end
  class OwnershipError < StandardError; end

  @reactor = Reactor.new

  class << self
    attr_reader :reactor
  end
end
