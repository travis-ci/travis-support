class Module
  class Preloader
    attr_reader :skip_patterns, :skip_names

    def initialize(options)
      skip = options[:skip] || []
      @skip_patterns, @skip_names = skip.partition do |skip|
        skip.is_a?(Regexp)
      end
    end

    def load_constants(const)
      const.constants.each do |name|
        full_name = [const.name, name].join('::')
        unless skip?(full_name)
          skip_names << full_name
          child = const.const_get(name)
          load_constants(child) if loadable?(child)
        end
      end
    end

    def skip?(name)
      skip_names.include?(name) || skip_patterns.any? { |pattern| pattern =~ name }
    end

    def loadable?(const)
      const.is_a?(Class) || const.is_a?(Module)
    end
  end

  def load_constants!(options = {})
    Preloader.new(options).load_constants(self)
  end
end
