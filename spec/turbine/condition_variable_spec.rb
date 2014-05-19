describe Turbine::ConditionVariable do
  let!(:m) { Mutex.new }
  let!(:c) { Turbine::ConditionVariable.new }

  describe "#wait_until" do
    it "raises an error if not given a block" do
      expect { c.wait_until(m) }.to raise_error(ArgumentError, "no block given")
      expect { c.wait_until(m, 1000) }.to raise_error(ArgumentError, "no block given")
    end

    describe "with a timeout" do
      it "waits until the condition is true, even if woken up spuriously" do
        i = 0
        done = false

        thread = Thread.new do
          m.synchronize do
            c.wait_until(m, 1000) do
              checkpoint (i += 1)
              done
            end
          end
        end

        wait_until_sleep(thread) # 1
        thread.wakeup
        wait_until_sleep(thread) # 2
        m.synchronize { done = true }
        thread.wakeup # 3

        thread.join(0.1).should_not be_nil
        checkpoints.should eq([1, 2, 3])
      end

      it "stops waiting once the timeout is reached" do
        thread = Thread.new do
          m.synchronize do
            c.wait_until(m, 0.1) { false }
          end
        end

        expect { thread.join }.to delay_for(0.1).seconds
      end
    end

    describe "without a timeout" do
      it "waits forever" do
        i = 0
        done = false

        thread = Thread.new do
          m.synchronize do
            c.wait_until(m) do
              checkpoint (i += 1)
              done
            end
          end
        end

        wait_until_sleep(thread) # 1
        thread.wakeup
        wait_until_sleep(thread) # 2
        m.synchronize { done = true }
        thread.wakeup # 3

        thread.join(0.1).should_not be_nil
        checkpoints.should eq([1, 2, 3])
      end
    end
  end
end
