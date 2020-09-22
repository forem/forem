RSpec.describe OAuth2::Authenticator do
  subject do
    described_class.new(client_id, client_secret, mode)
  end

  let(:client_id) { 'foo' }
  let(:client_secret) { 'bar' }
  let(:mode) { :undefined }

  it 'raises NotImplementedError for unknown authentication mode' do
    expect { subject.apply({}) }.to raise_error(NotImplementedError)
  end

  describe '#apply' do
    context 'with parameter-based authentication' do
      let(:mode) { :request_body }

      it 'adds client_id and client_secret to params' do
        output = subject.apply({})
        expect(output).to eq('client_id' => 'foo', 'client_secret' => 'bar')
      end

      it 'does not overwrite existing credentials' do
        input = {'client_secret' => 's3cr3t'}
        output = subject.apply(input)
        expect(output).to eq('client_id' => 'foo', 'client_secret' => 's3cr3t')
      end

      it 'preserves other parameters' do
        input = {'state' => '42', :headers => {'A' => 'b'}}
        output = subject.apply(input)
        expect(output).to eq(
          'client_id' => 'foo',
          'client_secret' => 'bar',
          'state' => '42',
          :headers => {'A' => 'b'}
        )
      end

      context 'using tls client authentication' do
        let(:mode) { :tls_client_auth }

        it 'does not add client_secret' do
          output = subject.apply({})
          expect(output).to eq('client_id' => 'foo')
        end
      end

      context 'using private key jwt authentication' do
        let(:mode) { :private_key_jwt }

        it 'does not include client_id or client_secret' do
          output = subject.apply({})
          expect(output).to eq({})
        end
      end
    end

    context 'with Basic authentication' do
      let(:mode) { :basic_auth }
      let(:header) { 'Basic ' + Base64.strict_encode64("#{client_id}:#{client_secret}") }

      it 'encodes credentials in headers' do
        output = subject.apply({})
        expect(output).to eq(:headers => {'Authorization' => header})
      end

      it 'does not overwrite existing credentials' do
        input = {:headers => {'Authorization' => 'Bearer abc123'}}
        output = subject.apply(input)
        expect(output).to eq(:headers => {'Authorization' => 'Bearer abc123'})
      end

      it 'does not overwrite existing params or headers' do
        input = {'state' => '42', :headers => {'A' => 'b'}}
        output = subject.apply(input)
        expect(output).to eq(
          'state' => '42',
          :headers => {'A' => 'b', 'Authorization' => header}
        )
      end
    end
  end
end
