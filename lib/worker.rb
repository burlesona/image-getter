module ImageGetter
  Thread.abort_on_exception = true
  # A generic in-memory worker with a pretty simple API
  #
  # Takes any queue of starting items and a task block on init
  # On #start, spins up n worker threads (default 1), calls task
  #   with each item until queue is empty
  # Threads idle when queue is empty
  # Accepts new items into the queue and continues background execution
  class Worker
    def initialize(items:[],threads:1,&block)
      raise ArgumentError, "Items must be enumerable" unless items.is_a?(Enumerable)
      @thread_count = threads
      @threads = []
      @queue = Queue.new
      items.each{|i| enqueue(i) }
      @task = block
    end

    def start
      @thread_count.times do
        @threads << Thread.new do
          loop { @task.call(@queue.shift) }
        end
      end
    end

    def stop
      @threads.map(&:exit)
      @threads = []
    end

    def enqueue(item)
      @queue << item
    end
  end
end
