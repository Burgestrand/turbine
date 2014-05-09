describe Turbine do
  describe ".reactor" do
    it "retrieves a global reactor" do
      Turbine.reactor.should be_a Turbine::Reactor
    end
  end
end
