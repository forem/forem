RSpec.describe OAuth2::Response do
  let(:raw_response) { Faraday::Response.new(:status => status, :response_headers => headers, :body => body) }
  let(:status) { 200 }
  let(:headers) { {'foo' => 'bar'} }
  let(:body) { 'foo' }

  let(:subject) { described_class.new(raw_response) }

  describe '#initialize' do
    it 'returns the status, headers and body' do
      expect(subject.headers).to eq(headers)
      expect(subject.status).to eq(status)
      expect(subject.body).to eq(body)
    end
  end

  describe '.register_parser' do
    let(:response) do
      double('response', :headers => {'Content-Type' => 'application/foo-bar'},
                         :status => 200,
                         :body => 'baz')
    end

    before do
      described_class.register_parser(:foobar, 'application/foo-bar') do |body|
        "foobar #{body}"
      end
    end

    it 'adds to the content types and parsers' do
      expect(described_class.send(:class_variable_get, :@@parsers).keys).to include(:foobar)
      expect(described_class.send(:class_variable_get, :@@content_types).keys).to include('application/foo-bar')
    end

    it 'is able to parse that content type automatically' do
      expect(described_class.new(response).parsed).to eq('foobar baz')
    end
  end

  describe '#content_type' do
    context 'when headers are blank' do
      let(:headers) { nil }

      it 'returns nil' do
        expect(subject.content_type).to be_nil
      end
    end

    context 'when content-type is not present' do
      let(:headers) { {'a fuzzy' => 'fuzzer'} }

      it 'returns empty string' do
        expect(subject.content_type).to eq('')
      end
    end

    context 'when content-type is present' do
      let(:headers) { {'Content-Type' => 'application/x-www-form-urlencoded'} }

      it 'returns the content type header contents' do
        expect(subject.content_type).to eq('application/x-www-form-urlencoded')
      end
    end
  end

  describe '#parsed' do
    it 'parses application/x-www-form-urlencoded body' do
      headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
      body = 'foo=bar&answer=42'
      response = double('response', :headers => headers, :body => body)
      subject = described_class.new(response)
      expect(subject.parsed.keys.size).to eq(2)
      expect(subject.parsed['foo']).to eq('bar')
      expect(subject.parsed['answer']).to eq('42')
    end

    it 'parses application/json body' do
      headers = {'Content-Type' => 'application/json'}
      body = MultiJson.encode(:foo => 'bar', :answer => 42)
      response = double('response', :headers => headers, :body => body)
      subject = described_class.new(response)
      expect(subject.parsed.keys.size).to eq(2)
      expect(subject.parsed['foo']).to eq('bar')
      expect(subject.parsed['answer']).to eq(42)
    end

    it 'parses alternative application/json extension bodies' do
      headers = {'Content-Type' => 'application/hal+json'}
      body = MultiJson.encode(:foo => 'bar', :answer => 42)
      response = double('response', :headers => headers, :body => body)
      subject = described_class.new(response)
      expect(subject.parsed.keys.size).to eq(2)
      expect(subject.parsed['foo']).to eq('bar')
      expect(subject.parsed['answer']).to eq(42)
    end

    it 'parses application/vnd.collection+json body' do
      headers = {'Content-Type' => 'application/vnd.collection+json'}
      body = MultiJson.encode(:collection => {})
      response = double('response', :headers => headers, :body => body)
      subject = described_class.new(response)
      expect(subject.parsed.keys.size).to eq(1)
    end

    it 'parses application/vnd.api+json body' do
      headers = {'Content-Type' => 'application/vnd.api+json'}
      body = MultiJson.encode(:collection => {})
      response = double('response', :headers => headers, :body => body)
      subject = described_class.new(response)
      expect(subject.parsed.keys.size).to eq(1)
    end

    it "parses application/Json body" do
      headers = {'Content-Type' => 'application/Json'}
      body = MultiJson.encode(:foo => 'bar', :answer => 42)
      response = double('response', :headers => headers, :body => body)
      subject = Response.new(response)
      expect(subject.parsed.keys.size).to eq(2)
      expect(subject.parsed['foo']).to eq('bar')
      expect(subject.parsed['answer']).to eq(42)
    end

    it "doesn't try to parse other content-types" do
      headers = {'Content-Type' => 'text/html'}
      body = '<!DOCTYPE html><html><head></head><body></body></html>'

      response = double('response', :headers => headers, :body => body)

      expect(MultiJson).not_to receive(:decode)
      expect(MultiJson).not_to receive(:load)
      expect(Rack::Utils).not_to receive(:parse_query)

      subject = described_class.new(response)
      expect(subject.parsed).to be_nil
    end

    it "should snakecase json keys when parsing" do
      headers = {'Content-Type' => 'application/json'}
      body = MultiJson.encode("accessToken" => 'bar', "MiGever" => "Ani")
      response = double('response', :headers => headers, :body => body)
      subject = Response.new(response)
      expect(subject.parsed.keys.size).to eq(2)
      expect(subject.parsed['access_token']).to eq('bar')
      expect(subject.parsed['mi_gever']).to eq("Ani")
    end

    it 'supports registered parsers with arity == 0; passing nothing' do
      described_class.register_parser(:arity_0, []) do
        'a-ok'
      end

      headers   = {'Content-Type' => 'text/html'}
      body      = '<!DOCTYPE html><html><head></head><body></body></html>'
      response  = double('response', :headers => headers, :body => body)

      subject = described_class.new(response, :parse => :arity_0)

      expect(subject.parsed).to eq('a-ok')
    end

    it 'supports registered parsers with arity == 2; passing body and response' do
      headers   = {'Content-Type' => 'text/html'}
      body      = '<!DOCTYPE html><html><head></head><body></body></html>'
      response  = double('response', :headers => headers, :body => body)

      described_class.register_parser(:arity_2, []) do |passed_body, passed_response|
        expect(passed_body).to eq(body)
        expect(passed_response).to eq(response)

        'a-ok'
      end

      subject = described_class.new(response, :parse => :arity_2)

      expect(subject.parsed).to eq('a-ok')
    end

    it 'supports registered parsers with arity > 2; passing body and response' do
      headers   = {'Content-Type' => 'text/html'}
      body      = '<!DOCTYPE html><html><head></head><body></body></html>'
      response  = double('response', :headers => headers, :body => body)

      described_class.register_parser(:arity_3, []) do |passed_body, passed_response, *args|
        expect(passed_body).to eq(body)
        expect(passed_response).to eq(response)
        expect(args).to eq([])

        'a-ok'
      end

      subject = described_class.new(response, :parse => :arity_3)

      expect(subject.parsed).to eq('a-ok')
    end

    it 'supports directly passed parsers' do
      headers   = {'Content-Type' => 'text/html'}
      body      = '<!DOCTYPE html><html><head></head><body></body></html>'
      response  = double('response', :headers => headers, :body => body)

      subject = described_class.new(response, :parse => lambda { 'a-ok' })

      expect(subject.parsed).to eq('a-ok')
    end
  end

  context 'with xml parser registration' do
    it 'tries to load multi_xml and use it' do
      expect(described_class.send(:class_variable_get, :@@parsers)[:xml]).not_to be_nil
    end

    it 'is able to parse xml' do
      headers = {'Content-Type' => 'text/xml'}
      body = '<?xml version="1.0" standalone="yes" ?><foo><bar>baz</bar></foo>'

      response = double('response', :headers => headers, :body => body)
      expect(described_class.new(response).parsed).to eq('foo' => {'bar' => 'baz'})
    end

    it 'is able to parse application/xml' do
      headers = {'Content-Type' => 'application/xml'}
      body = '<?xml version="1.0" standalone="yes" ?><foo><bar>baz</bar></foo>'

      response = double('response', :headers => headers, :body => body)
      expect(described_class.new(response).parsed).to eq('foo' => {'bar' => 'baz'})
    end
  end

  describe 'converting to json' do
    it 'does not blow up' do
      expect { subject.to_json }.not_to raise_error
    end
  end
end
