module Turbine
  class Thread < ::Thread
    def initialize(reactor, *args)
      @reactor = reactor
      super(*args)
    end

    attr_reader :reactor
  end
end
