# encoding: utf-8
require 'spec_helper'
require 'json'

module Travis
  describe Chunkifier do
    let(:chunk_size) { 15 }
    let(:chunk_split_size) { 1 }
    let(:subject) { Chunkifier.new(content, chunk_size, :json => true, :chunk_split_size => chunk_split_size) }

    context 'with newlines' do
      let(:content) { "01\n234501\n234501\n2345" }

      its(:parts) { should == ["01\n234501\n2", "34501\n2345"] }
    end

    context 'with non-UTF8 chars' do
      let(:content) { "\xC2\xE2".force_encoding('ASCII-8BIT') }

      its(:parts) { should == [content] }
    end

    context 'with UTF-8 chars' do
      let(:content) { "𤭢abcą" }

      its(:parts) { should == ["𤭢abc", "ą"] }

      it 'should keep parts under chunk_size taking into account conversion to json and bytes' do
        subject.parts.map { |p| p.to_json.bytesize }.should == [11, 8]
      end

    end

    context 'with bigger chunk_size' do
      let(:chunk_size) { 100 }
      let(:content) { "01\nąąąą" * 1000 }

      it 'should keep parts under chunk_size taking into account conversion to json and bytes' do
        subject.parts.all? { |p| p.to_json.bytesize <= 100 }.should == true
      end
    end

    it 'encodes UTF-8 chars' do
      chunkifier = Chunkifier.new("とと", 8, :json => true)
      chunkifier.parts.length.should == 2
    end
  end
end
