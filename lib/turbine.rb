require "turbine/fiber"
require "turbine/thread"

require "turbine/fifo"
require "turbine/task"
require "turbine/reactor"

module Turbine
  class Error < StandardError; end

  # Raised by {Turbine::Reactor} when attempting to mutate it after or
  # during shutdown.
  class DeadReactorError < StandardError; end

  # Raised by {Turbine::Reactor} when attempting to schedule the same
  # task more than once.
  class DoubleEnqueueError < StandardError; end

  # Raised by {Turbine::Task} when attempting to access private data
  # only allowed to be read by the owning thread.
  class OwnershipError < StandardError; end

  @reactor = Reactor.new

  class << self
    # @return [Turbine::Reactor]
    attr_reader :reactor
  end
end
