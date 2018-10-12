if defined?(Bunny)
  class ::Bunny::Channel
    def prefetch=(prefetch_count)
      prefetch(prefetch_count)
    end
  end
end
