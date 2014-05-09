describe Turbine::Thread do
  let(:reactor) { Object.new }

  describe ".current" do
    it "returns the current thread" do
      thread = Turbine::Thread.new(reactor) do
        Turbine::Thread.current
      end

      thread.value.should eql(thread)
    end
  end

  describe "#initialize" do
    it "passes all extra arguments to the underlying thread" do
      thread = Turbine::Thread.new(reactor, 1, "Hey", k: "Cool") do |*args, **kwargs|
        [args, kwargs]
      end

      thread_args, thread_kwargs = thread.value

      thread_args.should eq([1, "Hey"])
      thread_kwargs.should eq(k: "Cool")
    end
  end

  describe "#reactor" do
    it "returns the reactor the thread is powering" do
      thread = Turbine::Thread.new(reactor) {}
      thread.reactor.should eql(reactor)
    end
  end
end
