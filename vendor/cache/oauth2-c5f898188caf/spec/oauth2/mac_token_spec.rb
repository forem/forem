RSpec.describe MACToken do
  subject { described_class.new(client, token, 'abc123', kid: kid) }

  let(:kid) { 'this-token' }
  let(:token) { 'monkey' }
  let(:client) do
    Client.new('abc', 'def', :site => 'https://api.example.com') do |builder|
      builder.request :url_encoded
      builder.adapter :test do |stub|
        VERBS.each do |verb|
          stub.send(verb, '/token/header') { |env| [200, {}, env[:request_headers]['Authorization']] }
        end
      end
    end
  end

  describe '#initialize' do
    it 'assigns client and token' do
      expect(subject.client).to eq(client)
      expect(subject.token).to eq(token)
    end

    it 'assigns secret' do
      expect(subject.secret).to eq('abc123')
    end

    it 'defaults algorithm to hmac-sha-256' do
      expect(subject.algorithm).to be_instance_of(OpenSSL::Digest::SHA256)
    end

    it 'handles hmac-sha-256' do
      mac = described_class.new(client, token, 'abc123', :algorithm => 'hmac-sha-256')
      expect(mac.algorithm).to be_instance_of(OpenSSL::Digest::SHA256)
    end

    it 'handles hmac-sha-1' do
      mac = described_class.new(client, token, 'abc123', :algorithm => 'hmac-sha-1')
      expect(mac.algorithm).to be_instance_of(OpenSSL::Digest::SHA1)
    end

    it 'raises on improper algorithm' do
      expect { described_class.new(client, token, 'abc123', :algorithm => 'invalid-sha') }.to raise_error(ArgumentError)
    end
  end

  describe '#request' do
    VERBS.each do |verb|
      it "sends the token in the Authorization header for a #{verb.to_s.upcase} request" do
        expect(subject.post('/token/header').body).to include("MAC kid=\"#{kid}\"")
      end
    end
  end

  describe '#header' do
    it 'does not generate the same header twice' do
      header = subject.header('get', 'https://www.example.com/hello')
      duplicate_header = subject.header('get', 'https://www.example.com/hello')

      expect(header).not_to eq(duplicate_header)
    end

    it 'generates the proper format' do
      header = subject.header('get', 'https://www.example.com/hello?a=1')
      expect(header).to match(/MAC kid="#{kid}", ts="[0-9]+", seq-nr="[^"]+", mac="[^"]+"/)
    end

    it 'passes ArgumentError with an invalid url' do
      expect { subject.header('get', 'this-is-not-valid') }.to raise_error(ArgumentError)
    end

    it 'passes URI::InvalidURIError through' do
      expect { subject.header('get', '\\') }.to raise_error(URI::InvalidURIError)
    end

    it 'passes ArgumentError with nil url' do
      expect { subject.header('get', nil) }.to raise_error(ArgumentError)
    end

    it 'change seq-nr' do
      header = subject.header('get', 'https://www.example.com/hello?a=1')
      seq_nr_1 = header.match(/MAC kid="#{kid}", ts="[0-9]+", seq-nr="([^"]+)", mac="[^"]+"/)[1]

      header = subject.header('get', 'https://www.example.com/hello?a=1')
      seq_nr_2 = header.match(/MAC kid="#{kid}", ts="[0-9]+", seq-nr="([^"]+)", mac="[^"]+"/)[1]

      expect(seq_nr_1).not_to be_empty
      expect(seq_nr_2).not_to be_empty
      expect(seq_nr_2).not_to eq(seq_nr_1)
    end
  end

  describe '#signature' do
    let(:seq_nr_0) { 0 }

    before { allow(SecureRandom).to receive(:random_number).and_return(seq_nr_0) }

    it 'generates properly' do
      signature = subject.signature(0, 'get', URI('https://www.google.com'))
      expect(signature).to eq('ZdY7fRIXlCxKBVWMwv8jH53qxekdQ/I9TmOuszZ1Zvc=')
    end
  end

  describe '#headers' do
    it 'is an empty hash' do
      expect(subject.headers).to eq({})
    end
  end

  describe '.from_access_token' do
    subject { described_class.from_access_token(access_token, 'hello') }

    let(:access_token) do
      AccessToken.new(
        client, token,
        :expires_at => 1,
        :expires_in => 1,
        :refresh_token => 'abc',
        :random => 1
      )
    end

    it 'initializes client, token, and secret properly' do
      expect(subject.client).to eq(client)
      expect(subject.token).to eq(token)
      expect(subject.secret).to eq('hello')
    end

    it 'initializes configuration options' do
      expect(subject.expires_at).to eq(1)
      expect(subject.expires_in).to eq(1)
      expect(subject.refresh_token).to eq('abc')
    end

    it 'initializes params' do
      expect(subject.params).to eq(:random => 1)
    end
  end
end
