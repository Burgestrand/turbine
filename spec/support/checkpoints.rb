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
