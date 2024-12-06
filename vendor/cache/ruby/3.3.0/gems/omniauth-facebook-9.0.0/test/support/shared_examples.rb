# NOTE it would be useful if this lived in omniauth-oauth2 eventually
module OAuth2StrategyTests
  def self.included(base)
    base.class_eval do
      include ClientTests
      include AuthorizeParamsTests
      include CSRFAuthorizeParamsTests
      include TokenParamsTests
    end
  end
  
  module ClientTests
    extend BlockTestHelper
    
    test 'should be initialized with symbolized client_options' do
      @options = { client_options: { 'authorize_url' => 'https://example.com' } }
      assert_equal 'https://example.com', strategy.client.options[:authorize_url]
    end
  end

  module AuthorizeParamsTests
    extend BlockTestHelper
    
    test 'should include any authorize params passed in the :authorize_params option' do
      @options = { authorize_params: { foo: 'bar', baz: 'zip' } }
      assert_equal 'bar', strategy.authorize_params['foo']
      assert_equal 'zip', strategy.authorize_params['baz']
    end

    test 'should include top-level options that are marked as :authorize_options' do
      @options = { authorize_options: [:scope, :foo], scope: 'bar', foo: 'baz' }
      assert_equal 'bar', strategy.authorize_params['scope']
      assert_equal 'baz', strategy.authorize_params['foo']
    end
    
    test 'should exclude top-level options that are not passed' do
      @options = { authorize_options: [:bar] }
      refute_has_key :bar, strategy.authorize_params
      refute_has_key 'bar', strategy.authorize_params
    end
  end

  module CSRFAuthorizeParamsTests
    extend BlockTestHelper

    test 'should store random state in the session when none is present in authorize or request params' do
      assert_includes strategy.authorize_params.keys, 'state'
      refute_empty strategy.authorize_params['state']
      refute_empty strategy.session['omniauth.state']
      assert_equal strategy.authorize_params['state'], strategy.session['omniauth.state']
    end

    test 'should not store state in the session when present in authorize params vs. a random one' do
      @options = { authorize_params: { state: 'bar' } }
      refute_empty strategy.authorize_params['state']
      refute_equal 'bar', strategy.authorize_params[:state]
      refute_empty strategy.session['omniauth.state']
      refute_equal 'bar', strategy.session['omniauth.state']
    end

    test 'should not store state in the session when present in request params vs. a random one' do
      @request.stubs(:params).returns({ 'state' => 'foo' })
      refute_empty strategy.authorize_params['state']
      refute_equal 'foo', strategy.authorize_params[:state]
      refute_empty strategy.session['omniauth.state']
      refute_equal 'foo', strategy.session['omniauth.state']
    end
  end

  module TokenParamsTests
    extend BlockTestHelper
    
    test 'should include any authorize params passed in the :token_params option' do
      @options = { token_params: { foo: 'bar', baz: 'zip' } }
      assert_equal 'bar', strategy.token_params['foo']
      assert_equal 'zip', strategy.token_params['baz']
    end

    test 'should include top-level options that are marked as :token_options' do
      @options = { token_options: [:scope, :foo], scope: 'bar', foo: 'baz' }
      assert_equal 'bar', strategy.token_params['scope']
      assert_equal 'baz', strategy.token_params['foo']
    end
  end
end
