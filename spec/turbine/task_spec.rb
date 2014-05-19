describe Turbine::Task do
  let(:channel) { Queue.new }

  let(:reactor) { Object.new }
  let(:reactor_thread) do
    Turbine::Thread.new(reactor, channel) { |q| q.pop.fiber.resume }
  end

  let(:other_reactor) { Object.new }
  let(:other_thread) { Turbine::Thread.new(other_reactor) {} }

  let(:error_task) do
    Turbine::Task.new(reactor_thread) { raise "An error!" }
  end

  let(:value_task) do
    Turbine::Task.new(reactor_thread) { "A value!" }
  end

  let(:sleepy_task) do
    Turbine::Task.new(reactor_thread) { sleep }
  end

  describe ".current" do
    it "returns nil if not in a task" do
      Turbine::Task.current.should be_nil
    end

    it "returns the current task if in a task" do
      task = Turbine::Task.new(reactor_thread) { Turbine::Task.current }
      channel << task
      wait_until_done(reactor_thread)
      task.value.should eql(task)
    end
  end

  describe "#thread" do
    it "returns the task thread" do
      task = Turbine::Task.new(other_thread)
      task.thread.should eq(other_thread)
    end
  end

  describe "#reactor" do
    it "returns the task thread reactor" do
      task = Turbine::Task.new(other_thread)
      task.reactor.should eq(other_reactor)
    end
  end

  describe "#fiber" do
    it "raises an error if not the task thread" do
      task = Turbine::Task.new(other_thread)
      expect { task.fiber }.to raise_error(Turbine::OwnershipError)
    end
  end

  describe "#value" do
    let(:timeout) { 0.05 }
    let(:delta_diff) { 0.01 }

    specify "on the current task"
    specify "as a cyclic dependency"

    describe "from same reactor" do
      specify "when task is done"
      specify "when task is not done"

      specify "when task failed"
      specify "when waiting timed out without block"
      specify "when waiting timed out with block"
    end

    describe "from other reactor" do
      specify "when task is done"
      specify "when task is not done"

      specify "when task failed"
      specify "when waiting timed out without block"
      specify "when waiting timed out with block"
    end

    describe "from outside reactor" do
      specify "when task is done" do
        channel << value_task
        wait_until_done(reactor_thread)

        value_task.value.should eq "A value!"
      end

      it "when task failed" do
        channel << error_task
        wait_until_done(reactor_thread)

        expect { error_task.value }.to raise_error(RuntimeError, "An error!")
      end

      specify "when task is not done" do
        q = Queue.new

        task = Turbine::Task.new(reactor_thread) { q.pop }
        channel << task

        waiter = Thread.new(task, &:value)
        wait_until_sleep(waiter)
        q.push "A"

        waiter.value.should eq "A"
      end

      it "when waiting timed out without block" do
        channel << sleepy_task

        expect {
          expect { sleepy_task.value(timeout) }.to raise_error(TimeoutError, /#{timeout}s/)
        }.to delay_for(timeout).seconds
      end

      it "when waiting timed out with block" do
        channel << sleepy_task

        expect {
          sleepy_task.value(timeout) { :timeout }.should eq :timeout
        }.to delay_for(timeout).seconds
      end
    end
  end

  describe "#error?, #value? and #done?" do
    specify "if the task has errored" do
      channel << error_task
      wait_until_done(reactor_thread)

      error_task.should be_error
      error_task.should_not be_value
      error_task.should be_done
    end

    specify "if the task has succeeded" do
      channel << value_task
      wait_until_done(reactor_thread)

      value_task.should_not be_error
      value_task.should be_value
      value_task.should be_done
    end

    specify "if the task is not done" do
      channel << sleepy_task

      sleepy_task.should_not be_error
      sleepy_task.should_not be_value
      sleepy_task.should_not be_done
    end
  end
end
