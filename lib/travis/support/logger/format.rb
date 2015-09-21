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
        formatted = l2met_format % log_record_vars(severity, time, progname, message).tap do |vars|
          vars[:message] = vars[:message].to_s.strip.inspect
        end

        if message.respond_to?(:l2met_args)
          formatted = append_l2met_args(formatted, message.l2met_args)
        end

        formatted + "\n"
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

      def l2met_format
        @l2met_format ||= ''.tap do |s|
          s << 'time=%{formatted_time} ' if (time_format || config[:format_type] == 'l2met')
          s << 'level=%{severity_downcase} '
          s << 'app=%{process_name} ' if ENV['TRAVIS_PROCESS_NAME']
          s << 'pid=%{process_id} ' if config[:process_id]
          s << 'tid=%{thread_id} ' if config[:thread_id]
          s << 'msg=%{message}'
        end
      end

      def append_l2met_args(formatted, l2met_args)
        l2met_args.keys.sort.each do |key|
          formatted << " #{key}=#{l2met_args[key].inspect}"
        end
        formatted
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
