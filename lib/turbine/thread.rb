module Turbine
  class Thread < ::Thread
    def initialize(reactor, *args, **kwargs)
      @reactor = reactor
      super(*args, **kwargs)
    end

    attr_reader :reactor
  end
end
