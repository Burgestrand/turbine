module Turbine
  class Thread < ::Thread
    def initialize(reactor)
      @reactor = reactor
      super()
    end

    attr_reader :reactor
  end
end
