require 'active_support/json'

module Travis
  class Chunkifier < Struct.new(:content, :chunk_size, :options)
    include Enumerable

    def initialize(*)
      super

      self.options ||= {}

      @chunk_split_size = options[:chunk_split_size]
    end

    def json?
      options[:json]
    end

    def length
      parts.length
    end

    def each(&block)
      parts.each(&block)
    end

    def parts
      @parts ||= split
    end

    def split
      parts = content.scan(/.{1,#{chunk_split_size}}/m)
      chunks = []
      current_chunk = ''

      parts.each do |part|
        if too_big?(current_chunk + part)
          chunks << current_chunk
          current_chunk = part
        else
          current_chunk << part
        end
      end

      chunks << current_chunk if current_chunk.length > 0

      chunks
    end

    def chunk_split_size
      @chunk_split_size || begin
        size = chunk_size / 10
        size == 0 ? 1 : size
      end
    end

    def too_big?(current_chunk)
      if json?
        current_chunk = current_chunk.to_s.force_encoding('UTF-8').encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
        current_chunk = current_chunk.to_json
      end
      current_chunk.bytesize > chunk_size
    end
  end
end
