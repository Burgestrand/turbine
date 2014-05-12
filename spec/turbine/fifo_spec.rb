describe Turbine::FIFO do
  subject(:fifo) { Turbine::FIFO.new }

  it "is in FIFO order" do
    fifo.enqueue(:a)
    fifo.enqueue(:b)

    fifo.dequeue.should eq :a
    fifo.dequeue.should eq :b
    fifo.should be_empty
  end

  describe "#empty?" do
    it "is true if queue is empty" do
      fifo.should be_empty
    end

    it "is false if queue is not empty" do
      fifo.should be_empty
      fifo.enqueue(:a)
      fifo.should_not be_empty
    end
  end
end
