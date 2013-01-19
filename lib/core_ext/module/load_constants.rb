class Module
  class Preloader
    attr_reader :only_patterns, :only_names, :skip_patterns, :skip_names, :debug

    def initialize(options)
      skip = options[:skip] || []
      only = options[:only] || []
      @debug = options[:debug]

      partition = lambda do |thing|
        thing.is_a?(Regexp)
      end

      @skip_patterns, @skip_names = skip.partition &partition
      @only_patterns, @only_names = only.partition &partition
    end

    def load_constants(const)
      const.constants.each do |name|
        full_name = [const.name, name].join('::')
        if only?(full_name) && !skip?(full_name)
          skip_names << full_name
          puts "preloading #{full_name}" if debug
          child = begin
            const.const_get(name)
          rescue NameError => e
            eval("#{const}::#{name}")
          end
          load_constants(child) if loadable?(child)
        end
      end
    end

    def skip?(name)
      skip_names.include?(name) || skip_patterns.any? { |pattern| pattern =~ name }
    end

    def only?(name)
      (only_names.length == 0 && only_patterns.length == 0) ||
        only_names.include?(name) || only_patterns.any? { |pattern| pattern =~ name }
    end

    def loadable?(const)
      const.is_a?(Class) || const.is_a?(Module)
    end
  end

  def load_constants!(options = {})
    Preloader.new(options).load_constants(self)
  end
end
