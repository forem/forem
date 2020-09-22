require 'helper'

describe OmniAuth::FailureEndpoint do
  subject { OmniAuth::FailureEndpoint }

  context 'raise-out environment' do
    before do
      @rack_env = ENV['RACK_ENV']
      ENV['RACK_ENV'] = 'test'

      @default = OmniAuth.config.failure_raise_out_environments
      OmniAuth.config.failure_raise_out_environments = ['test']
    end

    it 'raises out the error' do
      expect do
        subject.call('omniauth.error' => StandardError.new('Blah'))
      end.to raise_error(StandardError, 'Blah')
    end

    it 'raises out an OmniAuth::Error if no omniauth.error is set' do
      expect { subject.call('omniauth.error.type' => 'example') }.to raise_error(OmniAuth::Error, 'example')
    end

    after do
      ENV['RACK_ENV'] = @rack_env
      OmniAuth.config.failure_raise_out_environments = @default
    end
  end

  context 'non-raise-out environment' do
    let(:env) do
      {'omniauth.error.type' => 'invalid_request', 'omniauth.error.strategy' => ExampleStrategy.new({})}
    end

    it 'is a redirect' do
      status, = *subject.call(env)
      expect(status).to eq(302)
    end

    it 'includes the SCRIPT_NAME' do
      _, head, = *subject.call(env.merge('SCRIPT_NAME' => '/random'))
      expect(head['Location']).to eq('/random/auth/failure?message=invalid_request&strategy=test')
    end

    it 'respects the configured path prefix' do
      allow(OmniAuth.config).to receive(:path_prefix).and_return('/boo')
      _, head, = *subject.call(env)
      expect(head['Location']).to eq('/boo/failure?message=invalid_request&strategy=test')
    end

    it 'includes the origin (escaped) if one is provided' do
      env['omniauth.origin'] = '/origin-example'
      _, head, = *subject.call(env)
      expect(head['Location']).to be_include('&origin=%2Forigin-example')
    end
  end
end
