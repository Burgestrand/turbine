module Turbine
  # A FIFO implements a collection of ordered values with no duplicates.
  #
  # FIFO is thread-safe.
  class FIFO
    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new

      @queue = []
      @unique = Set.new
    end

    # @return [Boolean] true if queue is empty
    def empty?
      @mutex.synchronize { @queue.empty? }
    end

    # Add an item to the queue.
    #
    # @param [#eql?, #hash] item
    # @return [Boolean] true if item was added, false if it was already in the queue
    def enqueue(item)
      @mutex.synchronize do
        if @unique.member?(item)
          false
        else
          @unique.add(item)
          @queue.push(item)
          @cond.signal
          true
        end
      end
    end

    # Remove an item from the queue. Blocks if the
    # queue is empty.
    def dequeue
      @mutex.synchronize do
        @cond.wait(@mutex) while @queue.empty?

        item = @queue.shift
        @unique.delete(item)
        item
      end
    end
  end
end
