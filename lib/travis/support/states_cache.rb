require 'dalli'
require 'connection_pool'
require 'active_support/core_ext/module/delegation'

module Travis
  class << self
    attr_writer :states_cache

    def states_cache
      @states_cache ||= Travis::StatesCache.new
    end
  end

  class StatesCache
    class CacheError < StandardError; end

    attr_reader :adapter

    delegate :fetch, :to => :adapter

    def initialize(options = {})
      @adapter = options[:adapter] || Memcached.new
    end

    def write(id, branch, data)
      data = { 'id' => data.id, 'state' => data.state.to_s } if data.respond_to?(:id)
      adapter.write(id, branch, data)
    end

    def fetch_state(id, branch)
      data = fetch(id, branch)
      data['state'].to_sym if data && data['state']
    end

    class TestAdapter
      attr_reader :calls
      def initialize
        @calls = []
      end

      def fetch(id, branch)
        calls << [:fetch, id, branch]
      end

      def write(id, branch, data)
        calls << [:write, id, branch, data]
      end

      def clear
        calls.clear
      end
    end

    class Memcached
      attr_reader :pool
      attr_accessor :jitter
      attr_accessor :ttl

      def initialize(options = {})
        @pool = ConnectionPool.new(:size => 10, :timeout => 3) do
          options[:client] || new_dalli_connection
        end
        @jitter = 0.5
        @ttl = 7.days
      end

      def fetch(id, branch = nil)
        data = get(key(id, branch))
        data ? JSON.parse(data) : nil
      end

      def write(id, branch, data)
        build_id = data['id']
        data     = data.to_json

        Travis.logger.info("[states-cache] Writing states cache for repo_id=#{id} branch=#{branch} build_id=#{build_id}")
        set(key(id), data) if update?(id, nil, build_id)
        set(key(id, branch), data) if update?(id, branch, build_id)
      end

      def update?(id, branch, build_id)
        data = fetch(id, branch)
        return true unless data

        current_id = data['id'].to_i
        new_id     = build_id.to_i
        stale      = new_id >= current_id

        Travis.logger.info(
          "[states-cache] Checking if cache is stale for repo_id=#{id} branch=#{branch}. " \
          "The cache is #{stale ? 'stale' : 'fresh' }, last cached build id=#{current_id}, we're checking build with id=#{new_id}"
        )

        return update
      end

      def key(id, branch = nil)
        key = "state:#{id}"
        key << "-#{branch}" if branch
        key
      end

      private

      def new_dalli_connection
        Dalli::Client.new(Travis.config.states_cache.memcached_servers, Travis.config.states_cache.memcached_options)
      end

      def get(key)
        retry_ring_error do
          pool.with { |client| client.get(key) }
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def set(key, data)
        retry_ring_error do
          pool.with { |client| client.set(key, data) }
          Travis.logger.info("[states-cache] Setting cache for key=#{key} data=#{data}")
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        Travis.logger.info("[states-cache] Writing cache key failed key=#{key} data=#{data}")
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def retry_ring_error
        retries = 0
        yield
      rescue Dalli::RingError
        retries += 1
        if retries <= 3
          # Sleep for up to 1/2 * (2^retries - 1) seconds
          # For retries <= 3, this means up to 3.5 seconds
          sleep(jitter * (rand(2 ** retries - 1) + 1))
          retry
        else
          raise
        end
      end
    end
  end
end
