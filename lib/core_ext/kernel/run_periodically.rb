module Kernel
  def run_periodically(interval, &block)
    Thread.new do
      loop do
        block.call
        sleep(interval)
      end
    end
  end
end
