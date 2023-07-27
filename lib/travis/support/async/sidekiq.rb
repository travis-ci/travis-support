# frozen_string_literal: true

begin
  require 'sidekiq'
rescue LoadError
end

module Travis
  module Async
    module Sidekiq
      class Worker
        include ::Sidekiq::Worker if defined?(::Sidekiq)

        def perform(uuid, target, method, *args)
          Travis.uuid = uuid
          eval(target).send(method, *args)
          # rescue Exception => e
          #   TODO make sure the exception can be caught here, pipe it to Sentry and
          #   requeue the job appropriately
        end
      end

      class << self
        def setup(url, options = {})
          ::Sidekiq.configure_client do |c|
            c.redis = { url:, namespace: options[:namespace], size: options[:pool_size] }
          end
        end

        def run(target, method, options, *args)
          queue   = options[:queue]
          retries = options[:retries]
          target  = target.name if target.is_a?(Module)
          args    = [Travis.uuid, target, method, *args]
          ::Sidekiq::Client.push('queue' => queue, 'retry' => retries, 'class' => Worker, 'args' => args)
        end
      end
    end
  end
end
