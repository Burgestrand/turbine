describe Turbine::Fiber do
  let(:task) { Object.new }

  describe ".current" do
    it "returns the current fiber" do
      fiber = Turbine::Fiber.new(task) do
        Turbine::Fiber.current
      end

      fiber.resume.should eql(fiber)
    end
  end

  describe "#task" do
    it "returns the task the fiber is powering" do
      fiber = Turbine::Fiber.new(task) {}
      fiber.task.should eql(task)
    end
  end
end
