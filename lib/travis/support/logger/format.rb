module Travis
  class Logger
    class Format
      def initialize(config = {})
        @config = config || {}
      end

      def call(severity, time, progname, message)
        send(
          "format_#{config[:format_type] || 'traditional'}",
          severity, time, progname, message
        )
      end

      private

      attr_reader :config

      def format_traditional(severity, time, progname, message)
        traditional_format % log_record_vars(severity, time, progname, message)
      end

      def format_l2met(severity, time, progname, message)
        vars = log_record_vars(severity, time, progname, message)

        l2met_args = {
          time: vars[:formatted_time],
          level: vars[:severity_downcase].to_sym,
          msg: vars[:message].strip
        }

        l2met_args[:tid] = vars[:thread_id] if config[:thread_id]
        l2met_args[:pid] = vars[:process_id] if config[:process_id]
        l2met_args[:app] = vars[:process_name] if ENV['TRAVIS_PROCESS_NAME']

        if message.respond_to?(:l2met_args)
          l2met_args.merge!(message.l2met_args)
        end

        l2met_args_to_record(l2met_args).strip + "\n"
      end

      def log_record_vars(severity, time, progname, message)
        {
          message: message.to_s,
          process_id: Process.pid,
          process_name: ENV['TRAVIS_PROCESS_NAME'],
          progname: progname,
          severity: severity,
          severity_downcase: severity.downcase,
          severity_initial: severity[0, 1],
          thread_id: Thread.current.object_id,
          time: time
        }.tap do |v|
          if time_format
            v[:formatted_time] = time.strftime(time_format)
          elsif config[:format_type] == 'l2met'
            v[:formatted_time] = time.iso8601
          end
        end
      end

      def time_format
        @time_format ||= config[:time_format]
      end

      def l2met_args_to_record(l2met_args)
        args = l2met_args.dup
        ''.tap do |s|
          (builtin_l2met_args + (args.keys.sort - builtin_l2met_args)).each do |key|
            value = args.delete(key)
            value = value.inspect if value.respond_to?(:include?) && value.include?(' ')
            s << "#{key}=#{value} "
          end
        end
      end

      def builtin_l2met_args
        @builtin_l2met_args ||= %w(time level msg).map(&:to_sym)
      end

      def traditional_format
        @traditional_format ||= ''.tap do |s|
          s << '%{formatted_time} ' if time_format
          s << '%{severity_initial} '
          s << 'app[%{process_name}]: ' if ENV['TRAVIS_PROCESS_NAME']
          s << 'PID=%{process_id} ' if config[:process_id]
          s << 'TID=%{thread_id} ' if config[:thread_id]
          s << '%{message}'
        end
      end
    end
  end
end
