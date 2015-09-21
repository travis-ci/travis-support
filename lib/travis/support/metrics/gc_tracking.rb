require 'metriks'
require 'objspace'

module Travis
  module GithubSync
    module GcTracking
      class << self
        def setup_gc_stat(prefix)
          GC.stat.each do |key, _value|
            ::Metriks.gauge("#{prefix}.#{key}") do
              GC.stat(key)
            end
          end
        end

        def setup_object_space(prefix)
          Thread.new do
            loop do
              ObjectSpace.count_objects.each do |key, value|
                pretty_key = key.to_s.downcase.gsub(/^t_/, '')
                ::Metriks.gauge("#{prefix}.#{pretty_key}").set(value)
              end
              ObjectSpace.count_tdata_objects.each do |key, value|
                pretty_key = key.to_s.downcase.gsub(/::/, '_').gsub(':', '')
                ::Metriks.gauge("#{prefix}.#{pretty_key}").set(value)
              end
              sleep 5
            end
          end
        end
      end
    end
  end
end
