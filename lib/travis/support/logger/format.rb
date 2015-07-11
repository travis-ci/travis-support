module Travis
  class Logger
    class Format
      def initialize(config = {})
        (class << self; self; end).class_eval <<-rb
          def format(severity, time, progname, message)
            #{compile_format(config || {})}
          end
        rb
      end

      def call(severity, time, progname, message)
        format(severity, time, progname, message)
      end

      private

        def compile_format(config)
          format = '"'
          format << "\#{time.strftime('#{config[:time_format]}')} " if config[:time_format]
          format << '#{severity[0, 1]} '
          format << "app[#{ENV['TRAVIS_PROCESS_NAME']}]: "          if ENV['TRAVIS_PROCESS_NAME']
          format << 'PID=#{Process.pid} '                           if config[:process_id]
          format << 'TID=#{Thread.current.object_id.to_s[-4, 4]} '  if config[:thread_id]
          format << '#{message}'
          format << '"'
        end
    end
  end
end
