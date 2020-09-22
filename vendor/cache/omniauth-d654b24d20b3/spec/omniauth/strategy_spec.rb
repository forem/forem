require 'helper'

def make_env(path = '/auth/test', props = {})
  {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => path,
    'rack.session' => {},
    'rack.input' => StringIO.new('test=true')
  }.merge(props)
end

describe OmniAuth::Strategy do
  let(:app) do
    lambda { |_env| [404, {}, ['Awesome']] }
  end

  let(:fresh_strategy) do
    c = Class.new
    c.send(:include, OmniAuth::Strategy)
  end

  describe '.default_options' do
    it 'is inherited from a parent class' do
      superklass = Class.new
      superklass.send :include, OmniAuth::Strategy
      superklass.configure do |c|
        c.foo = 'bar'
      end

      klass = Class.new(superklass)
      expect(klass.default_options.foo).to eq('bar')
    end
  end

  describe '.configure' do
    subject do
      c = Class.new
      c.send(:include, OmniAuth::Strategy)
    end

    context 'when block is passed' do
      it 'allows for default options setting' do
        subject.configure do |c|
          c.wakka = 'doo'
        end
        expect(subject.default_options['wakka']).to eq('doo')
      end

      it "works when block doesn't evaluate to true" do
        environment_variable = nil
        subject.configure do |c|
          c.abc = '123'
          c.hgi = environment_variable
        end
        expect(subject.default_options['abc']).to eq('123')
      end
    end

    it 'takes a hash and deep merge it' do
      subject.configure :abc => {:def => 123}
      subject.configure :abc => {:hgi => 456}
      expect(subject.default_options['abc']).to eq('def' => 123, 'hgi' => 456)
    end
  end

  describe '#skip_info?' do
    it 'is true if options.skip_info is true' do
      expect(ExampleStrategy.new(app, :skip_info => true)).to be_skip_info
    end

    it 'is false if options.skip_info is false' do
      expect(ExampleStrategy.new(app, :skip_info => false)).not_to be_skip_info
    end

    it 'is false by default' do
      expect(ExampleStrategy.new(app)).not_to be_skip_info
    end

    it 'is true if options.skip_info is a callable that evaluates to truthy' do
      instance = ExampleStrategy.new(app, :skip_info => lambda { |uid| uid })
      expect(instance).to receive(:uid).and_return(true)
      expect(instance).to be_skip_info
    end
  end

  describe '.option' do
    subject do
      c = Class.new
      c.send(:include, OmniAuth::Strategy)
    end
    it 'sets a default value' do
      subject.option :abc, 123
      expect(subject.default_options.abc).to eq(123)
    end

    it 'sets the default value to nil if none is provided' do
      subject.option :abc
      expect(subject.default_options.abc).to be_nil
    end
  end

  describe '.args' do
    subject do
      c = Class.new
      c.send(:include, OmniAuth::Strategy)
    end

    it 'sets args to the specified argument if there is one' do
      subject.args %i[abc def]
      expect(subject.args).to eq(%i[abc def])
    end

    it 'is inheritable' do
      subject.args %i[abc def]
      c = Class.new(subject)
      expect(c.args).to eq(%i[abc def])
    end

    it 'accepts corresponding options as default arg values' do
      subject.args %i[a b]
      subject.option :a, '1'
      subject.option :b, '2'

      expect(subject.new(nil).options.a).to eq '1'
      expect(subject.new(nil).options.b).to eq '2'
      expect(subject.new(nil, '3', '4').options.b).to eq '4'
      expect(subject.new(nil, nil, '4').options.a).to eq nil
    end
  end

  context 'fetcher procs' do
    subject { fresh_strategy }
    %w[uid info credentials extra].each do |fetcher|
      describe ".#{fetcher}" do
        it 'sets and retrieve a proc' do
          proc = lambda { 'Hello' }
          subject.send(fetcher, &proc)
          expect(subject.send(fetcher)).to eq(proc)
        end
      end
    end
  end

  context 'fetcher stacks' do
    subject { fresh_strategy }
    %w[uid info credentials extra].each do |fetcher|
      describe ".#{fetcher}_stack" do
        it 'is an array of called ancestral procs' do
          fetchy = proc { 'Hello' }
          subject.send(fetcher, &fetchy)
          expect(subject.send("#{fetcher}_stack", subject.new(app))).to eq(['Hello'])
        end
      end
    end
  end

  %w[request_phase].each do |abstract_method|
    context abstract_method.to_s do
      it 'raises a NotImplementedError' do
        strat = Class.new
        strat.send :include, OmniAuth::Strategy
        expect { strat.new(app).send(abstract_method) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#auth_hash' do
    subject do
      klass = Class.new
      klass.send :include, OmniAuth::Strategy
      klass.option :name, 'auth_hasher'
      klass
    end
    let(:instance) { subject.new(app) }

    it 'calls through to uid and info' do
      expect(instance).to receive(:uid)
      expect(instance).to receive(:info)
      instance.auth_hash
    end

    it 'returns an AuthHash' do
      allow(instance).to receive(:uid).and_return('123')
      allow(instance).to receive(:info).and_return(:name => 'Hal Awesome')
      hash = instance.auth_hash
      expect(hash).to be_kind_of(OmniAuth::AuthHash)
      expect(hash.uid).to eq('123')
      expect(hash.info.name).to eq('Hal Awesome')
    end
  end

  describe '#initialize' do
    context 'options extraction' do
      it 'is the last argument if the last argument is a Hash' do
        expect(ExampleStrategy.new(app, :abc => 123).options[:abc]).to eq(123)
      end

      it 'is the default options if any are provided' do
        allow(ExampleStrategy).to receive(:default_options).and_return(OmniAuth::Strategy::Options.new(:abc => 123))
        expect(ExampleStrategy.new(app).options.abc).to eq(123)
      end
    end

    context 'custom args' do
      subject do
        c = Class.new
        c.send(:include, OmniAuth::Strategy)
      end

      it 'sets options based on the arguments if they are supplied' do
        subject.args %i[abc def]
        s = subject.new app, 123, 456
        expect(s.options[:abc]).to eq(123)
        expect(s.options[:def]).to eq(456)
      end
    end
  end

  describe '#call' do
    it 'duplicates and calls' do
      klass = Class.new
      klass.send :include, OmniAuth::Strategy
      instance = klass.new(app)
      expect(instance).to receive(:dup).and_return(instance)
      instance.call('rack.session' => {})
    end

    it 'raises NoSessionError if rack.session isn\'t set' do
      klass = Class.new
      klass.send :include, OmniAuth::Strategy
      instance = klass.new(app)
      expect { instance.call({}) }.to raise_error(OmniAuth::NoSessionError)
    end
  end

  describe '#inspect' do
    it 'returns the class name' do
      expect(ExampleStrategy.new(app).inspect).to eq('#<ExampleStrategy>')
    end
  end

  describe '#redirect' do
    it 'uses javascript if :iframe is true' do
      response = ExampleStrategy.new(app, :iframe => true).redirect('http://abc.com')
      expected_body = "<script type='text/javascript' charset='utf-8'>top.location.href = 'http://abc.com';</script>"

      expect(response.last).to include(expected_body)
    end
  end

  describe '#callback_phase' do
    subject do
      c = Class.new
      c.send(:include, OmniAuth::Strategy)
      c.new(app)
    end

    it 'sets the auth hash' do
      env = make_env
      allow(subject).to receive(:env).and_return(env)
      allow(subject).to receive(:auth_hash).and_return('AUTH HASH')
      subject.callback_phase
      expect(env['omniauth.auth']).to eq('AUTH HASH')
    end
  end

  describe '#full_host' do
    let(:strategy) { ExampleStrategy.new(app, {}) }
    it 'remains calm when there is a pipe in the URL' do
      strategy.call!(make_env('/whatever', 'rack.url_scheme' => 'http', 'SERVER_NAME' => 'facebook.lame', 'QUERY_STRING' => 'code=asofibasf|asoidnasd', 'SCRIPT_NAME' => '', 'SERVER_PORT' => 80))
      expect { strategy.full_host }.not_to raise_error
    end
  end

  describe '#uid' do
    subject { fresh_strategy }
    it "is the current class's uid if one exists" do
      subject.uid { 'Hi' }
      expect(subject.new(app).uid).to eq('Hi')
    end

    it 'inherits if it can' do
      subject.uid { 'Hi' }
      c = Class.new(subject)
      expect(c.new(app).uid).to eq('Hi')
    end
  end

  %w[info credentials extra].each do |fetcher|
    subject { fresh_strategy }
    it "is the current class's proc call if one exists" do
      subject.send(fetcher) { {:abc => 123} }
      expect(subject.new(app).send(fetcher)).to eq(:abc => 123)
    end

    it 'inherits by merging with preference for the latest class' do
      subject.send(fetcher) { {:abc => 123, :def => 456} }
      c = Class.new(subject)
      c.send(fetcher) { {:abc => 789} }
      expect(c.new(app).send(fetcher)).to eq(:abc => 789, :def => 456)
    end
  end

  describe '#call' do
    before(:all) do
      @options = nil
    end

    let(:strategy) { ExampleStrategy.new(app, @options || {}) }

    context 'omniauth.origin' do
      context 'disabled' do
        it 'does not set omniauth.origin' do
          @options = {:origin_param => false}
          expect { strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'return=/foo')) }.to raise_error('Request Phase')
          expect(strategy.last_env['rack.session']['omniauth.origin']).to eq(nil)
        end
      end

      context 'custom' do
        it 'sets from a custom param' do
          @options = {:origin_param => 'return'}
          expect { strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'return=/foo')) }.to raise_error('Request Phase')
          expect(strategy.last_env['rack.session']['omniauth.origin']).to eq('/foo')
        end
      end

      context 'default flow' do
        it 'is set on the request phase' do
          expect { strategy.call(make_env('/auth/test', 'HTTP_REFERER' => 'http://example.com/origin')) }.to raise_error('Request Phase')
          expect(strategy.last_env['rack.session']['omniauth.origin']).to eq('http://example.com/origin')
        end

        it 'is turned into an env variable on the callback phase' do
          expect { strategy.call(make_env('/auth/test/callback', 'rack.session' => {'omniauth.origin' => 'http://example.com/origin'})) }.to raise_error('Callback Phase')
          expect(strategy.last_env['omniauth.origin']).to eq('http://example.com/origin')
        end

        it 'sets from the params if provided' do
          expect { strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'origin=/foo')) }.to raise_error('Request Phase')
          expect(strategy.last_env['rack.session']['omniauth.origin']).to eq('/foo')
        end

        it 'is set on the failure env' do
          expect(OmniAuth.config).to receive(:on_failure).and_return(lambda { |env| env })
          @options = {:failure => :forced_fail}
          strategy.call(make_env('/auth/test/callback', 'rack.session' => {'omniauth.origin' => '/awesome'}))
        end

        context 'with script_name' do
          it 'is set on the request phase, containing full path' do
            env = {'HTTP_REFERER' => 'http://example.com/sub_uri/origin', 'SCRIPT_NAME' => '/sub_uri'}
            expect { strategy.call(make_env('/auth/test', env)) }.to raise_error('Request Phase')
            expect(strategy.last_env['rack.session']['omniauth.origin']).to eq('http://example.com/sub_uri/origin')
          end

          it 'is turned into an env variable on the callback phase, containing full path' do
            env = {
              'rack.session' => {'omniauth.origin' => 'http://example.com/sub_uri/origin'},
              'SCRIPT_NAME' => '/sub_uri'
            }

            expect { strategy.call(make_env('/auth/test/callback', env)) }.to raise_error('Callback Phase')
            expect(strategy.last_env['omniauth.origin']).to eq('http://example.com/sub_uri/origin')
          end
        end
      end
    end

    context 'default paths' do
      it 'uses the default request path' do
        expect { strategy.call(make_env) }.to raise_error('Request Phase')
      end

      it 'is case insensitive on request path' do
        expect { strategy.call(make_env('/AUTH/Test')) }.to raise_error('Request Phase')
      end

      it 'is case insensitive on callback path' do
        expect { strategy.call(make_env('/AUTH/TeSt/CaLlBAck')) }.to raise_error('Callback Phase')
      end

      it 'uses the default callback path' do
        expect { strategy.call(make_env('/auth/test/callback')) }.to raise_error('Callback Phase')
      end

      it 'strips trailing spaces on request' do
        expect { strategy.call(make_env('/auth/test/')) }.to raise_error('Request Phase')
      end

      it 'strips trailing spaces on callback' do
        expect { strategy.call(make_env('/auth/test/callback/')) }.to raise_error('Callback Phase')
      end

      context 'callback_url' do
        it 'uses the default callback_path' do
          expect(strategy).to receive(:full_host).and_return('http://example.com')

          expect { strategy.call(make_env) }.to raise_error('Request Phase')

          expect(strategy.callback_url).to eq('http://example.com/auth/test/callback')
        end

        it 'preserves the query parameters' do
          allow(strategy).to receive(:full_host).and_return('http://example.com')
          begin
            strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'id=5'))
          rescue RuntimeError
          end
          expect(strategy.callback_url).to eq('http://example.com/auth/test/callback?id=5')
        end

        it 'consider script name' do
          allow(strategy).to receive(:full_host).and_return('http://example.com')
          begin
            strategy.call(make_env('/auth/test', 'SCRIPT_NAME' => '/sub_uri'))
          rescue RuntimeError
          end
          expect(strategy.callback_url).to eq('http://example.com/sub_uri/auth/test/callback')
        end
      end
    end

    context ':form option' do
      it 'calls through to the supplied form option if one exists' do
        strategy.options.form = lambda { |_env| 'Called me!' }
        expect(strategy.call(make_env('/auth/test'))).to eq('Called me!')
      end

      it 'calls through to the app if :form => true is set as an option' do
        strategy.options.form = true
        expect(strategy.call(make_env('/auth/test'))).to eq(app.call(make_env('/auth/test')))
      end
    end

    context 'dynamic paths' do
      it 'runs the request phase if the custom request path evaluator is truthy' do
        @options = {:request_path => lambda { |_env| true }}
        expect { strategy.call(make_env('/asoufibasfi')) }.to raise_error('Request Phase')
      end

      it 'runs the callback phase if the custom callback path evaluator is truthy' do
        @options = {:callback_path => lambda { |_env| true }}
        expect { strategy.call(make_env('/asoufiasod')) }.to raise_error('Callback Phase')
      end

      it 'provides a custom callback path if request_path evals to a string' do
        strategy_instance = fresh_strategy.new(nil, :request_path => lambda { |_env| '/auth/boo/callback/22' })
        expect(strategy_instance.callback_path).to eq('/auth/boo/callback/22')
      end

      it 'correctly reports the callback path when the custom callback path evaluator is truthy' do
        strategy_instance = ExampleStrategy.new(app, :callback_path => lambda { |env| env['PATH_INFO'] == '/auth/bish/bosh/callback' })

        expect { strategy_instance.call(make_env('/auth/bish/bosh/callback')) }.to raise_error('Callback Phase')
        expect(strategy_instance.callback_path).to eq('/auth/bish/bosh/callback')
      end
    end

    context 'custom paths' do
      it 'uses a custom request_path if one is provided' do
        @options = {:request_path => '/awesome'}
        expect { strategy.call(make_env('/awesome')) }.to raise_error('Request Phase')
      end

      it 'uses a custom callback_path if one is provided' do
        @options = {:callback_path => '/radical'}
        expect { strategy.call(make_env('/radical')) }.to raise_error('Callback Phase')
      end

      context 'callback_url' do
        it 'uses a custom callback_path if one is provided' do
          @options = {:callback_path => '/radical'}
          expect(strategy).to receive(:full_host).and_return('http://example.com')

          expect { strategy.call(make_env('/radical')) }.to raise_error('Callback Phase')

          expect(strategy.callback_url).to eq('http://example.com/radical')
        end

        it 'preserves the query parameters' do
          @options = {:callback_path => '/radical'}
          allow(strategy).to receive(:full_host).and_return('http://example.com')
          begin
            strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'id=5'))
          rescue RuntimeError
          end
          expect(strategy.callback_url).to eq('http://example.com/radical?id=5')
        end
      end
    end

    context 'custom prefix' do
      before do
        @options = {:path_prefix => '/wowzers'}
      end

      it 'uses a custom prefix for request' do
        expect { strategy.call(make_env('/wowzers/test')) }.to raise_error('Request Phase')
      end

      it 'uses a custom prefix for callback' do
        expect { strategy.call(make_env('/wowzers/test/callback')) }.to raise_error('Callback Phase')
      end

      context 'callback_url' do
        it 'uses a custom prefix' do
          expect(strategy).to receive(:full_host).and_return('http://example.com')

          expect { strategy.call(make_env('/wowzers/test')) }.to raise_error('Request Phase')

          expect(strategy.callback_url).to eq('http://example.com/wowzers/test/callback')
        end

        it 'preserves the query parameters' do
          allow(strategy).to receive(:full_host).and_return('http://example.com')
          begin
            strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'id=5'))
          rescue RuntimeError
          end
          expect(strategy.callback_url).to eq('http://example.com/wowzers/test/callback?id=5')
        end
      end
    end

    context 'request method restriction' do
      before do
        OmniAuth.config.allowed_request_methods = [:post]
      end

      it 'does not allow a request method of the wrong type' do
        expect { strategy.call(make_env) }.not_to raise_error
      end

      it 'allows a request method of the correct type' do
        expect { strategy.call(make_env('/auth/test', 'REQUEST_METHOD' => 'POST')) }.to raise_error('Request Phase')
      end

      after do
        OmniAuth.config.allowed_request_methods = %i[get post]
      end
    end

    context 'receiving an OPTIONS request' do
      shared_examples_for 'an OPTIONS request' do
        it 'responds with 200' do
          expect(response[0]).to eq(200)
        end

        it 'sets the Allow header properly' do
          expect(response[1]['Allow']).to eq('GET, POST')
        end
      end

      context 'to the request path' do
        let(:response) { strategy.call(make_env('/auth/test', 'REQUEST_METHOD' => 'OPTIONS')) }
        it_behaves_like 'an OPTIONS request'
      end

      context 'to the request path' do
        let(:response) { strategy.call(make_env('/auth/test/callback', 'REQUEST_METHOD' => 'OPTIONS')) }
        it_behaves_like 'an OPTIONS request'
      end

      context 'to some other path' do
        it 'does not short-circuit the request' do
          env = make_env('/other', 'REQUEST_METHOD' => 'OPTIONS')
          expect(strategy.call(env)).to eq(app.call(env))
        end
      end
    end

    context 'options mutation' do
      before do
        @options = {:dup => true}
      end

      context 'in request phase' do
        it 'does not affect original options' do
          @options[:test_option] = true
          @options[:mutate_on_request] = proc { |options| options.delete(:test_option) }
          expect { strategy.call(make_env) }.to raise_error('Request Phase')
          expect(strategy.options).to have_key(:test_option)
        end

        it 'does not affect deep options' do
          @options[:deep_option] = {:test_option => true}
          @options[:mutate_on_request] = proc { |options| options[:deep_option].delete(:test_option) }
          expect { strategy.call(make_env) }.to raise_error('Request Phase')
          expect(strategy.options[:deep_option]).to have_key(:test_option)
        end
      end

      context 'in callback phase' do
        it 'does not affect original options' do
          @options[:test_option] = true
          @options[:mutate_on_callback] = proc { |options| options.delete(:test_option) }
          expect { strategy.call(make_env('/auth/test/callback', 'REQUEST_METHOD' => 'POST')) }.to raise_error('Callback Phase')
          expect(strategy.options).to have_key(:test_option)
        end

        it 'does not affect deep options' do
          @options[:deep_option] = {:test_option => true}
          @options[:mutate_on_callback] = proc { |options| options[:deep_option].delete(:test_option) }
          expect { strategy.call(make_env('/auth/test/callback', 'REQUEST_METHOD' => 'POST')) }.to raise_error('Callback Phase')
          expect(strategy.options[:deep_option]).to have_key(:test_option)
        end
      end
    end

    context 'test mode' do
      let(:app) do
        # In test mode, the underlying app shouldn't be called on request phase.
        lambda { |_env| [404, {'Content-Type' => 'text/html'}, []] }
      end

      before do
        OmniAuth.config.test_mode = true
      end

      it 'short circuits the request phase entirely' do
        response = strategy.call(make_env)
        expect(response[0]).to eq(302)
        expect(response[1]['Location']).to eq('/auth/test/callback')
      end

      it "doesn't short circuit the request if request method is not allowed" do
        response = strategy.call(make_env('/auth/test', 'REQUEST_METHOD' => 'DELETE'))
        expect(response[0]).to eq(404)
      end

      it 'is case insensitive on request path' do
        expect(strategy.call(make_env('/AUTH/Test'))[0]).to eq(302)
      end

      it 'respects SCRIPT_NAME (a.k.a. BaseURI)' do
        response = strategy.call(make_env('/auth/test', 'SCRIPT_NAME' => '/sub_uri'))
        expect(response[1]['Location']).to eq('/sub_uri/auth/test/callback')
      end

      it 'redirects on failure' do
        response = OmniAuth.config.on_failure.call(make_env('/auth/test', 'omniauth.error.type' => 'error'))
        expect(response[0]).to eq(302)
        expect(response[1]['Location']).to eq('/auth/failure?message=error')
      end

      it 'respects SCRIPT_NAME (a.k.a. BaseURI) on failure' do
        response = OmniAuth.config.on_failure.call(make_env('/auth/test', 'SCRIPT_NAME' => '/sub_uri', 'omniauth.error.type' => 'error'))
        expect(response[0]).to eq(302)
        expect(response[1]['Location']).to eq('/sub_uri/auth/failure?message=error')
      end

      it 'is case insensitive on callback path' do
        expect(strategy.call(make_env('/AUTH/TeSt/CaLlBAck')).first).to eq(strategy.call(make_env('/auth/test/callback')).first)
      end

      it 'maintains host and port' do
        response = strategy.call(make_env('/auth/test', 'rack.url_scheme' => 'http', 'SERVER_NAME' => 'example.org', 'SERVER_PORT' => 9292))
        expect(response[1]['Location']).to eq('http://example.org:9292/auth/test/callback')
      end

      it 'maintains query string parameters' do
        response = strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'cheese=stilton'))
        expect(response[1]['Location']).to eq('/auth/test/callback?cheese=stilton')
      end

      it 'does not short circuit requests outside of authentication' do
        expect(strategy.call(make_env('/'))).to eq(app.call(make_env('/')))
      end

      it 'responds with the default hash if none is set' do
        OmniAuth.config.mock_auth[:test] = nil

        strategy.call make_env('/auth/test/callback')
        expect(strategy.env['omniauth.auth']['uid']).to eq('1234')
      end

      it 'responds with a provider-specific hash if one is set' do
        OmniAuth.config.mock_auth[:test] = {
          'uid' => 'abc'
        }

        strategy.call make_env('/auth/test/callback')
        expect(strategy.env['omniauth.auth']['uid']).to eq('abc')
      end

      it 'simulates login failure if mocked data is set as a symbol' do
        OmniAuth.config.mock_auth[:test] = :invalid_credentials

        strategy.call make_env('/auth/test/callback')
        expect(strategy.env['omniauth.error.type']).to eq(:invalid_credentials)
      end

      context 'omniauth.origin' do
        context 'disabled' do
          it 'does not set omniauth.origin' do
            @options = {:origin_param => false}
            strategy.call(make_env('/auth/test', 'HTTP_REFERER' => 'http://example.com/origin'))
            expect(strategy.env['rack.session']['omniauth.origin']).to be_nil
          end
        end

        context 'default flow' do
          it 'sets omniauth.origin to the HTTP_REFERER on the request phase by default' do
            strategy.call(make_env('/auth/test', 'HTTP_REFERER' => 'http://example.com/origin'))
            expect(strategy.env['rack.session']['omniauth.origin']).to eq('http://example.com/origin')
          end

          it 'sets omniauth.origin from the params if provided' do
            strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'origin=/foo'))
            expect(strategy.env['rack.session']['omniauth.origin']).to eq('/foo')
          end
        end

        context 'custom' do
          it 'sets omniauth.origin from a custom param' do
            @options = {:origin_param => 'return'}
            strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'return=/foo'))
            expect(strategy.env['rack.session']['omniauth.origin']).to eq('/foo')
          end
        end
      end

      it 'turns omniauth.origin into an env variable on the callback phase' do
        OmniAuth.config.mock_auth[:test] = {}

        strategy.call(make_env('/auth/test/callback', 'rack.session' => {'omniauth.origin' => 'http://example.com/origin'}))
        expect(strategy.env['omniauth.origin']).to eq('http://example.com/origin')
      end

      it 'executes callback hook on the callback phase' do
        OmniAuth.config.mock_auth[:test] = {}
        OmniAuth.config.before_callback_phase do |env|
          env['foobar'] = 'baz'
        end
        strategy.call(make_env('/auth/test/callback', 'rack.session' => {'omniauth.origin' => 'http://example.com/origin'}))
        expect(strategy.env['foobar']).to eq('baz')
      end

      it 'sets omniauth.params with query params on the request phase' do
        OmniAuth.config.mock_auth[:test] = {}

        strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'foo=bar'))
        expect(strategy.env['rack.session']['omniauth.params']).to eq('foo' => 'bar')
      end

      it 'does not set body parameters of POST request on the request phase' do
        OmniAuth.config.mock_auth[:test] = {}

        props = {
          'REQUEST_METHOD' => 'POST',
          'rack.input' => StringIO.new('foo=bar')
        }
        strategy.call(make_env('/auth/test', props))
        expect(strategy.env['rack.session']['omniauth.params']).to eq({})
      end

      it 'executes request hook on the request phase' do
        OmniAuth.config.mock_auth[:test] = {}
        OmniAuth.config.before_request_phase do |env|
          env['foobar'] = 'baz'
        end
        strategy.call(make_env('/auth/test', 'QUERY_STRING' => 'foo=bar'))
        expect(strategy.env['foobar']).to eq('baz')
      end

      it 'turns omniauth.params into an env variable on the callback phase' do
        OmniAuth.config.mock_auth[:test] = {}

        strategy.call(make_env('/auth/test/callback', 'rack.session' => {'omniauth.params' => {'foo' => 'bar'}}))
        expect(strategy.env['omniauth.params']).to eq('foo' => 'bar')
      end

      after do
        OmniAuth.config.test_mode = false
      end
    end

    context 'custom full_host' do
      before do
        OmniAuth.config.test_mode = true
      end

      it 'is the string when a string is there' do
        OmniAuth.config.full_host = 'my.host.com'
        expect(strategy.full_host).to eq('my.host.com')
      end

      it 'runs the proc with the env when it is a proc' do
        OmniAuth.config.full_host = proc { |env| env['HOST'] }
        strategy.call(make_env('/auth/test', 'HOST' => 'my.host.net'))
        expect(strategy.full_host).to eq('my.host.net')
      end

      it "is based on the request if it's not a string nor a proc" do
        OmniAuth.config.full_host = nil
        strategy.call(make_env('/whatever', 'rack.url_scheme' => 'http', 'SERVER_NAME' => 'my.host.net', 'SERVER_PORT' => 80))
        expect(strategy.full_host).to eq('http://my.host.net')
      end

      it 'honors HTTP_X_FORWARDED_PROTO if present' do
        OmniAuth.config.full_host = nil
        strategy.call(make_env('/whatever', 'HTTP_X_FORWARDED_PROTO' => 'https', 'rack.url_scheme' => 'http', 'SERVER_NAME' => 'my.host.net', 'SERVER_PORT' => 443))
        expect(strategy.full_host).to eq('https://my.host.net')
      end

      after do
        OmniAuth.config.full_host = nil
        OmniAuth.config.test_mode = false
      end
    end
  end

  context 'setup phase' do
    before do
      OmniAuth.config.test_mode = true
    end

    context 'when options[:setup] = true' do
      let(:strategy) do
        ExampleStrategy.new(app, :setup => true)
      end

      let(:app) do
        lambda do |env|
          env['omniauth.strategy'].options[:awesome] = 'sauce' if env['PATH_INFO'] == '/auth/test/setup'
          [404, {}, 'Awesome']
        end
      end

      it 'calls through to /auth/:provider/setup' do
        strategy.call(make_env('/auth/test'))
        expect(strategy.options[:awesome]).to eq('sauce')
      end

      it 'does not call through on a non-omniauth endpoint' do
        strategy.call(make_env('/somewhere/else'))
        expect(strategy.options[:awesome]).not_to eq('sauce')
      end
    end

    context 'when options[:setup] is an app' do
      let(:setup_proc) do
        proc do |env|
          env['omniauth.strategy'].options[:awesome] = 'sauce'
        end
      end

      let(:strategy) { ExampleStrategy.new(app, :setup => setup_proc) }

      it 'does not call the app on a non-omniauth endpoint' do
        strategy.call(make_env('/somehwere/else'))
        expect(strategy.options[:awesome]).not_to eq('sauce')
      end

      it 'calls the rack app' do
        strategy.call(make_env('/auth/test'))
        expect(strategy.options[:awesome]).to eq('sauce')
      end
    end

    after do
      OmniAuth.config.test_mode = false
    end
  end
end
