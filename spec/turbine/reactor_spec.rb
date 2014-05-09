describe Turbine::Reactor do
  subject(:reactor) { Turbine::Reactor.new }

  describe ".current" do
    it "returns the current reactor if inside a reactor" do
      task = reactor.spawn do
        Turbine::Reactor.current
      end

      task.value.should eql(reactor)
    end

    it "returns nil if not inside a reactor" do
      Turbine::Reactor.current.should be_nil
    end
  end

  describe "#crashed?" do
  end

  describe "#error" do
  end

  describe "#spawn" do
    it "raises an error if no block was given" do
      expect { reactor.spawn }.to raise_error(ArgumentError, "no block given")
    end

    it "raises an error if spawned inside the reactor" do
      task = reactor.spawn do
        subtask = reactor.spawn { "B" }
        ["A", subtask.value]
      end

      expect { task.value }.to raise_error(Turbine::Error, "cannot spawn task in current reactor")
    end

    it "creates and schedules a task for execution" do
      task = reactor.spawn { "This is a value" }
      task.thread.should eql(reactor.thread)
      task.thread.should_not eql(Thread.current)
      task.value.should eq "This is a value"
    end
  end

  describe "#shutdown" do
  end
end
