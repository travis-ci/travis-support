require 'travis/support/logging/url'

describe Travis::Logging::Url do
  subject { described_class.new(url).strip_secrets }

  describe 'with user:password' do
    let(:url) { 'http://user:password@host.com' }

    it 'strips the password' do
      expect(subject).to eq 'http://user:(secret)@host.com'
    end
  end

  describe 'with a query param :secret' do
    let(:url) { 'http://host.com/path?foo=bar&secret=12345' }

    it 'strips the param' do
      expect(subject).to eq 'http://host.com/path?foo=bar&secret=[secret]'
    end
  end

  describe 'with a query param :token' do
    let(:url) { 'http://host.com/path?foo=bar&token=12345' }

    it 'strips the param' do
      expect(subject).to eq 'http://host.com/path?foo=bar&token=[secret]'
    end
  end

  describe 'with a query param :password' do
    let(:url) { 'http://host.com/path?foo=bar&password=12345' }

    it 'strips the param' do
      expect(subject).to eq 'http://host.com/path?foo=bar&password=[secret]'
    end
  end
end
