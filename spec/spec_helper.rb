require "turbine"
require "pry"

Thread.abort_on_exception = true

module Checkpoints
  Lock = Mutex.new

  attr_reader :checkpoints

  def checkpoint(name)
    Lock.synchronize do
      @checkpoints ||= []
      @checkpoints << name
    end
  end
end

RSpec.configure do |config|
  config.include(Checkpoints)
end
