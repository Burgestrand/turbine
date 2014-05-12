module Turbine
  class Thread < ::Thread
    def initialize(reactor, *args)
      @reactor = reactor
      super(*args)
    end

    # @return [Turbine::Reactor] the reactor assigned to this thread
    attr_reader :reactor
  end
end
