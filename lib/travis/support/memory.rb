# frozen_string_literal: true

require 'java'
require 'metriks'
require 'core_ext/kernel/run_periodically'

module Travis
  class Memory
    import java.lang.management.ManagementFactory

    attr_reader :app

    def initialize(app)
      @app = app
    end

    def report_periodically
      run_periodically(60) do
        log
        meter
      rescue Exception => e
        puts e.message, e.backtrace
      end
    end

    def log
      stats.each do |key, value|
        puts "[memory] #{key}: #{value}"
      end
    end

    def meter
      %i[used committed].each do |key|
        Metriks.meter("v1.travis.#{app}.memory.heap.#{key}").mark(heap.send(key))
      end
    end

    private

    def stats
      { heap:, non_heap:, waiting: }
    end

    def heap
      memory_manager.heap_memory_usage
    end

    def non_heap
      memory_manager.non_heap_memory_usage
    end

    def waiting
      memory_manager.object_pending_finalization_count
    end

    def memory_manager
      @memory_manager ||= ManagementFactory.memoryMXBean
    end

    # def gc_beans
    #   @gc_beans ||= ManagementFactory.garbageCollectorMXBeans
    # end

    # def memory_managers
    #   ManagementFactory.memory_manager_mxbeans
    # end

    # def memory_pools
    #   ManagementFactory.memory_pool_mxbeans
    # end
  end
end
