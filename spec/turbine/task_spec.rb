describe Turbine::Task do
  let(:other_thread) { Thread.new {} }
  let(:channel) { Queue.new }
  let(:reactor) do
    Thread.new(channel) do |q|
      q.pop.fiber.resume
    end
  end

  let(:error_task) do
    Turbine::Task.new(reactor) { raise "An error!" }
  end

  let(:value_task) do
    Turbine::Task.new(reactor) { "A value!" }
  end

  let(:sleepy_task) do
    Turbine::Task.new(reactor) { sleep }
  end

  describe ".current" do
    it "returns nil if not in a task" do
      Turbine::Task.current.should be_nil
    end

    it "returns the current task if in a task" do
      task = Turbine::Task.new(reactor) { Turbine::Task.current }
      channel << task
      reactor.join
      task.value.should eql(task)
    end
  end

  describe "#thread" do
    it "returns the task thread" do
      task = Turbine::Task.new(other_thread)
      task.thread.should eq(other_thread)
    end
  end

  describe "#fiber" do
    it "raises an error if not the task thread" do
      task = Turbine::Task.new(other_thread)
      expect { task.fiber }.to raise_error(Turbine::OwnershipError)
    end

    it "returns the underlying task fiber if we are the task thread" do
      task_thread = Thread.new(channel) { |q| q.pop.fiber }

      task = Turbine::Task.new(task_thread)
      channel << task
      fiber = task_thread.value

      fiber.should be_a(Turbine::Fiber)
      fiber.task.should eq(task)
    end
  end

  describe "#value" do
    let(:timeout) { 0.05 }
    let(:delta_diff) { 0.005 }

    it "waits if there is no value available" do
      task = Turbine::Task.new(reactor) do
        start = Time.now
        sleep 0.1
        ["Duration", start - Time.now]
      end

      channel << task

      init = Time.now
      label, value = task.value
      delta = init - Time.now

      label.should eq "Duration"
      value.should be_within(delta_diff).of(delta)
    end

    it "returns the value if one is available" do
      channel << value_task
      reactor.join

      # Double-check.
      value_task.value.should eq "A value!"
      value_task.value.should eq "A value!"
    end

    it "raises the error if one is available" do
      channel << error_task
      reactor.join rescue nil

      # Double-check.
      expect { error_task.value }.to raise_error(RuntimeError, "An error!")
      expect { error_task.value }.to raise_error(RuntimeError, "An error!")
    end

    it "raises a timeout error if timed out" do
      channel << sleepy_task

      start = Time.now
      expect { sleepy_task.value(timeout) }.to raise_error(TimeoutError, /#{timeout}s/)
      (Time.now - start).should be_within(delta_diff).of(timeout)
    end

    it "yields if timed out and block given" do
      channel << sleepy_task

      start = Time.now
      sleepy_task.value(timeout) { :timeout }.should eq :timeout
      (Time.now - start).should be_within(delta_diff).of(timeout)
    end
  end

  describe "#error?" do
    specify "if the task has errored" do
      channel << error_task
      reactor.join rescue nil

      error_task.should be_error
    end

    specify "if the task has succeeded" do
      channel << value_task
      reactor.join

      value_task.should_not be_error
    end

    specify "if the task is not done" do
      channel << sleepy_task

      sleepy_task.should_not be_error
    end
  end

  describe "#value?" do
    specify "if the task has errored" do
      channel << error_task
      reactor.join rescue nil

      error_task.should_not be_value
    end

    specify "if the task has succeeded" do
      channel << value_task
      reactor.join

      value_task.should be_value
    end

    specify "if the task is not done" do
      channel << sleepy_task

      sleepy_task.should_not be_value
    end
  end

  describe "#done?" do
    specify "if the task has errored" do
      channel << error_task
      reactor.join rescue nil

      error_task.should be_done
    end

    specify "if the task has succeeded" do
      channel << value_task
      reactor.join

      value_task.should be_done
    end

    specify "if the task is not done" do
      channel << sleepy_task

      sleepy_task.should_not be_done
    end
  end
end
