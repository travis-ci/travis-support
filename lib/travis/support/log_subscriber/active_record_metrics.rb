# frozen_string_literal: true

require 'active_support/log_subscriber'

module Travis
  module LogSubscriber
    class ActiveRecordMetrics < ActiveSupport::LogSubscriber
      def self.attach
        attach_to(:active_record)
      end

      def sql(event)
        return if event.payload[:name] == 'SCHEMA'

        name = event.payload[:name]
        sql = event.payload[:sql].downcase
        duration = event.duration
        name = 'generic' if name.is_a?(Array)

        metric_name =
          if name.present?
            Metriks.timer('active_record.reads').update(duration)
            "active_record.#{name.downcase.gsub(/ /, '.')}"
          elsif %w[insert delete update].include?(sql[0..6])
            Metriks.timer('active_record.writes').update(duration)
            # Metriks.timer("active_record.log_updates").update(duration) if log_update?(sql)
            "active_record.#{sql[0..6]}"
          end

        Metriks.timer(metric_name).update(duration)
      end

      # need to define a logger outside of rails so events won't be skipped
      def logger
        Travis.logger
      end

      private

      def log_update?(sql)
        sql.include?('artifacts') && sql.include?("content = coalesce(content, '')")
      end
    end
  end
end
