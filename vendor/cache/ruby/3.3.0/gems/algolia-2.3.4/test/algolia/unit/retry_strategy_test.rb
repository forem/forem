require 'algolia'
require 'test_helper'

class RetryStrategyTest
  include RetryOutcomeType
  include CallType
  describe 'get tryable hosts' do
    def before_all
      super
      @app_id        = 'app_id'
      @api_key       = 'api_key'
      stateful_hosts = []
      stateful_hosts << "#{@app_id}-4.algolianet.com"
      stateful_hosts << "#{@app_id}-5.algolianet.com"
      stateful_hosts << "#{@app_id}-6.algolianet.com"
      @config        = Algolia::Search::Config.new(application_id: @app_id, api_key: @api_key, custom_hosts: stateful_hosts)
    end

    def test_resets_expired_hosts_according_to_read_type
      @config.default_hosts[1].up = false
      retry_strategy              = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(READ)
      assert_equal 2, hosts.length
    end

    def test_resets_expired_hosts_according_to_write_type
      @config.default_hosts[1].up = false
      retry_strategy              = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(WRITE)
      assert_equal 2, hosts.length
    end

    def test_resets_expired_hosts_according_to_read_type_with_timeout
      @config.default_hosts[1].up       = false
      @config.default_hosts[1].last_use = Time.new.utc - 1000
      retry_strategy                    = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(READ)
      assert_equal 3, hosts.length
    end

    def test_resets_expired_hosts_according_to_write_type_with_timeout
      @config.default_hosts[1].up       = false
      @config.default_hosts[1].last_use = Time.new.utc - 1000
      retry_strategy                    = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(WRITE)
      assert_equal 3, hosts.length
    end

    def test_resets_all_hosts_when_expired_according_to_read_type
      0.upto(2).map do |i|
        @config.default_hosts[i].up = false
      end
      retry_strategy        = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(READ)
      assert_equal 3, hosts.length
    end

    def test_resets_all_hosts_when_expired_according_to_write_type
      0.upto(2).map do |i|
        @config.default_hosts[i].up = false
      end
      retry_strategy        = Algolia::Transport::RetryStrategy.new(@config)

      hosts = retry_strategy.get_tryable_hosts(WRITE)
      assert_equal 3, hosts.length
    end
  end

  describe 'All hosts are unreachable' do
    def test_failure_when_all_hosts_are_down
      stateful_hosts = ['0.0.0.0']
      @config        = Algolia::Search::Config.new(application_id: 'foo', api_key: 'bar', custom_hosts: stateful_hosts)
      client         = Algolia::Search::Client.create_with_config(@config)
      index          = client.init_index(get_test_index_name('failure'))

      exception = assert_raises Algolia::AlgoliaUnreachableHostError do
        index.save_object({ objectID: 'one' })
      end

      assert_equal 'Unreachable hosts', exception.message
    end
  end

  describe 'retry stategy decisions' do
    def before_all
      super
      @app_id         = 'app_id'
      @api_key        = 'api_key'
      @config         = Algolia::Search::Config.new(application_id: @app_id, api_key: @api_key)
      @retry_strategy = Algolia::Transport::RetryStrategy.new(@config)
      @hosts          = @retry_strategy.get_tryable_hosts(READ|WRITE)
    end

    def test_retry_decision_on_300
      decision = @retry_strategy.decide(@hosts.first, http_response_code: 300)
      assert_equal RETRY, decision
    end

    def test_retry_decision_on_500
      retry_strategy = Algolia::Transport::RetryStrategy.new(@config)

      decision = retry_strategy.decide(@hosts.first, http_response_code: 500)
      assert_equal RETRY, decision
    end

    def test_retry_decision_on_timed_out
      retry_strategy = Algolia::Transport::RetryStrategy.new(@config)

      decision = retry_strategy.decide(@hosts.first, is_timed_out: true)
      assert_equal RETRY, decision
    end

    def test_retry_decision_on_400
      retry_strategy = Algolia::Transport::RetryStrategy.new(@config)

      decision = retry_strategy.decide(@hosts.first, http_response_code: 400)
      assert_equal FAILURE, decision
    end

    def test_retry_decision_on_404
      retry_strategy = Algolia::Transport::RetryStrategy.new(@config)

      decision = retry_strategy.decide(@hosts.first, http_response_code: 404)
      assert_equal FAILURE, decision
    end

    def test_retry_decision_on_200
      retry_strategy = Algolia::Transport::RetryStrategy.new(@config)

      decision = retry_strategy.decide(@hosts.first, http_response_code: 200)
      assert_equal SUCCESS, decision
    end
  end
end
