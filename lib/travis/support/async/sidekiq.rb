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
        end
      end

      class << self
        def setup(url, options = {})
          ::Sidekiq.configure_client do |c|
            c.redis = { :url => url, :namespace => options[:namespace], :size => options[:pool_size] }
          end
        end

        def run(target, method, options, *args)
          target  = target.name if target.is_a?(Module)
          now     = Time.now.to_f
          at      = now + options[:in].to_f

          payload = {
            'queue' => options[:queue],
            'retry' => options[:retries],
            'class' => Worker,
            'args'  => [Travis.uuid, target, method, *args]
          }
          payload = payload.merge('at' => at) if at > now

          ::Sidekiq::Client.push(payload)
        end
      end
    end
  end
end
