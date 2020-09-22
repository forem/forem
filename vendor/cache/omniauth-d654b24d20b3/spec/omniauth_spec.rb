require 'helper'

describe OmniAuth do
  describe '.strategies' do
    it 'increases when a new strategy is made' do
      expect do
        class ExampleStrategy
          include OmniAuth::Strategy
        end
      end.to change(OmniAuth.strategies, :size).by(1)
      expect(OmniAuth.strategies.last).to eq(ExampleStrategy)
    end
  end

  context 'configuration' do
    describe '.defaults' do
      it 'is a hash of default configuration' do
        expect(OmniAuth::Configuration.defaults).to be_kind_of(Hash)
      end
    end

    it 'is callable from .configure' do
      OmniAuth.configure do |c|
        expect(c).to be_kind_of(OmniAuth::Configuration)
      end
    end

    before do
      @old_path_prefix           = OmniAuth.config.path_prefix
      @old_on_failure            = OmniAuth.config.on_failure
      @old_before_callback_phase = OmniAuth.config.before_callback_phase
      @old_before_options_phase  = OmniAuth.config.before_options_phase
      @old_before_request_phase  = OmniAuth.config.before_request_phase
    end

    after do
      OmniAuth.configure do |config|
        config.path_prefix           = @old_path_prefix
        config.on_failure            = @old_on_failure
        config.before_callback_phase = @old_before_callback_phase
        config.before_options_phase  = @old_before_options_phase
        config.before_request_phase  = @old_before_request_phase
      end
    end

    it 'is able to set the path' do
      OmniAuth.configure do |config|
        config.path_prefix = '/awesome'
      end

      expect(OmniAuth.config.path_prefix).to eq('/awesome')
    end

    it 'is able to set the on_failure rack app' do
      OmniAuth.configure do |config|
        config.on_failure do
          'yoyo'
        end
      end

      expect(OmniAuth.config.on_failure.call).to eq('yoyo')
    end

    it 'is able to set hook on option_call' do
      OmniAuth.configure do |config|
        config.before_options_phase do
          'yoyo'
        end
      end
      expect(OmniAuth.config.before_options_phase.call).to eq('yoyo')
    end

    it 'is able to set hook on request_call' do
      OmniAuth.configure do |config|
        config.before_request_phase do
          'heyhey'
        end
      end
      expect(OmniAuth.config.before_request_phase.call).to eq('heyhey')
    end

    it 'is able to set hook on callback_call' do
      OmniAuth.configure do |config|
        config.before_callback_phase do
          'heyhey'
        end
      end
      expect(OmniAuth.config.before_callback_phase.call).to eq('heyhey')
    end

    describe 'mock auth' do
      before do
        @auth_hash = {:uid => '12345', :info => {:name => 'Joe', :email => 'joe@example.com'}}
        @original_auth_hash = @auth_hash.dup

        OmniAuth.config.add_mock(:facebook, @auth_hash)
      end
      it 'default is AuthHash' do
        OmniAuth.configure do |config|
          expect(config.mock_auth[:default]).to be_kind_of(OmniAuth::AuthHash)
        end
      end
      it 'facebook is AuthHash' do
        OmniAuth.configure do |config|
          expect(config.mock_auth[:facebook]).to be_kind_of(OmniAuth::AuthHash)
        end
      end
      it 'sets facebook attributes' do
        OmniAuth.configure do |config|
          expect(config.mock_auth[:facebook].uid).to eq('12345')
          expect(config.mock_auth[:facebook].info.name).to eq('Joe')
          expect(config.mock_auth[:facebook].info.email).to eq('joe@example.com')
        end
      end
      it 'does not mutate given auth hash' do
        OmniAuth.configure do
          expect(@auth_hash).to eq @original_auth_hash
        end
      end
    end
  end

  describe '.logger' do
    it 'calls through to the configured logger' do
      allow(OmniAuth).to receive(:config).and_return(double(:logger => 'foo'))
      expect(OmniAuth.logger).to eq('foo')
    end
  end

  describe '::Utils' do
    describe '.deep_merge' do
      it 'combines hashes' do
        expect(OmniAuth::Utils.deep_merge({'abc' => {'def' => 123}}, 'abc' => {'foo' => 'bar'})).to eq('abc' => {'def' => 123, 'foo' => 'bar'})
      end
    end

    describe '.camelize' do
      it 'works on normal cases' do
        {
          'some_word' => 'SomeWord',
          'AnotherWord' => 'AnotherWord',
          'one' => 'One',
          'three_words_now' => 'ThreeWordsNow'
        }.each_pair { |k, v| expect(OmniAuth::Utils.camelize(k)).to eq(v) }
      end

      it 'works in special cases that have been added' do
        OmniAuth.config.add_camelization('oauth', 'OAuth')
        expect(OmniAuth::Utils.camelize(:oauth)).to eq('OAuth')
      end
    end
  end
end
