RSpec.describe Flipper::Middleware::SetupEnv do
  context 'with flipper instance' do
    let(:app) do
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/html' }, [env['flipper'].object_id.to_s]]
      end
      builder = Rack::Builder.new
      builder.use described_class, flipper
      builder.run app
      builder
    end

    it 'sets flipper in env' do
      get '/'
      expect(last_response.body).to eq(flipper.object_id.to_s)
    end
  end

  context 'with block that returns flipper instance' do
    let(:flipper_block) do
      -> { flipper }
    end
    let(:app) do
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/html' }, [env['flipper'].object_id.to_s]]
      end
      builder = Rack::Builder.new
      builder.use described_class, flipper_block
      builder.run app
      builder
    end

    it 'sets flipper in env' do
      get '/'
      expect(last_response.body).to eq(flipper.object_id.to_s)
    end
  end

  context 'when env already has flipper setup' do
    let(:app) do
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/html' }, [env['flipper'].object_id.to_s]]
      end
      builder = Rack::Builder.new
      builder.use described_class, flipper
      builder.run app
      builder
    end

    it 'leaves env flipper alone' do
      env_flipper = build_flipper
      get '/', {}, 'flipper' => env_flipper
      expect(last_response.body).to eq(env_flipper.object_id.to_s)
    end
  end

  context 'when flipper instance or block are nil but env flipper is configured' do
    let(:app) do
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/html' }, [env['flipper'].object_id.to_s]]
      end
      builder = Rack::Builder.new
      builder.use described_class
      builder.run app
      builder
    end

    it 'can use env flipper' do
      env_flipper = build_flipper
      get '/', {}, 'flipper' => env_flipper
      expect(last_response.body).to eq(env_flipper.object_id.to_s)
    end
  end

  context 'when flipper instance or block are nil and default Flipper is configured' do
    let(:app) do
      Flipper.configure do |config|
        config.default { flipper }
      end
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/html' }, [env['flipper'].object_id.to_s]]
      end
      builder = Rack::Builder.new
      builder.use described_class
      builder.run app
      builder
    end

    it 'can use env flipper' do
      get '/', {}, {}
      expect(last_response.body).to eq(Flipper.object_id.to_s)
    end
  end
end
