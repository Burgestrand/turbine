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
    it "is true if the reactor is running" do
      reactor.should be_alive
    end

    it "is false if reactor has crashed" do
      task = reactor.spawn { raise "OMG" }
      reactor.thread.join rescue nil
      reactor.should_not be_alive
    end

    it "is false if the reactor is shutting down" do
      task = reactor.spawn { sleep }
      reactor.shutdown
      reactor.should_not be_alive
    end

    it "is false if the reactor has shut down" do
      reactor.shutdown
      reactor.thread.join rescue nil
      reactor.should_not be_alive
    end
  end

  describe "#crashed?" do
    it "is false if the reactor is running" do
      reactor.should_not be_crashed
    end

    it "is true if reactor has crashed" do
      task = reactor.spawn { raise "OMG" }
      reactor.thread.join rescue nil
      reactor.should be_crashed
    end

    it "is false if the reactor is shutting down" do
      task = reactor.spawn { sleep }
      reactor.shutdown
      reactor.should_not be_crashed
    end

    it "is false if the reactor has shut down" do
      reactor.shutdown
      reactor.thread.join rescue nil
      reactor.should_not be_crashed
    end
  end

  describe "#error" do
    it "returns the error that crashed the reactor" do
      error = RuntimeError.new("This is an error")
      task = reactor.spawn { raise error }
      reactor.thread.join rescue nil
      reactor.error.should eql(error)
    end
  end

  describe "#spawn" do
    it "raises an error if no block was given" do
      expect { reactor.spawn }.to raise_error(ArgumentError, "no block given")
    end

    it "raises an error if spawned inside the reactor" do
      task = reactor.spawn do
        begin
          reactor.spawn { "B" }
        rescue => error
          error
        else
          raise "This was a failure"
        end
      end

      task.value.should be_a(Turbine::Error)
      task.value.message.should eq "cannot spawn task in current reactor"
    end

    it "creates and schedules a task for execution" do
      task = reactor.spawn { "This is a value" }
      task.thread.should eql(reactor.thread)
      task.thread.should_not eql(Thread.current)
      task.value.should eq "This is a value"
    end

    it "raises an error if reactor is in the process of shutting down" do
      task = reactor.spawn { sleep } # prevent reactor from shutting down
      reactor.shutdown

      expect { reactor.spawn {} }.to raise_error(Turbine::DeadReactorError, "reactor is terminated")
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
    it "cleanly terminates the reactor, letting any scheduled tasks finish first" do
      order = Queue.new
      start = Queue.new

      reactor.spawn { start.pop }
      reactor.spawn { order << "A" }
      reactor.spawn { order << "B" }
      reactor.shutdown { order << "C" }

      start.push(nil)

      a = order.pop
      b = order.pop
      c = order.pop

      [a, b, c].should eq(["A", "B", "C"])

      reactor.thread.join
    end

    it "executes the given block as a final task" do
      task = reactor.shutdown { "A" }
      task.value.should eq "A"
    end
  end
end
