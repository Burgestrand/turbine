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

  describe "#alive?" do
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

    it "schedules tasks in the order they were spawned" do
      queue = Queue.new
      start = Queue.new

      reactor.spawn { start.pop; queue << "A" }
      reactor.spawn { start.pop; queue << "B" }

      start.push(nil)
      start.push(nil)

      a = queue.pop
      b = queue.pop

      a.should eq "A"
      b.should eq "B"
    end

    it "raises an error if reactor is not alive" do
      reactor.shutdown

      expect { reactor.spawn {} }.to raise_error(Turbine::DeadReactorError, "reactor is terminated")
    end
  end

  describe "#shutdown" do
  end
end
