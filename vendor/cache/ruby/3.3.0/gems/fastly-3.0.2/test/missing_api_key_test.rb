require 'helper'

class MissingApiKeyTest < Fastly::TestCase
  include CommonTests

  def setup
    # missing API key
    @opts = login_opts(:full)
    begin
      @client = Fastly::Client.new(@opts)
      @fastly = Fastly.new(@opts)
    rescue Exception => e
      pp e
      exit(-1)
    end
  end

  def test_purging
    service_name = "fastly-test-service-#{random_string}"
    service      = @fastly.create_service(:name => service_name)

    assert_raises Fastly::KeyAuthRequired do
      service.purge_by_key('somekey')
    end
  ensure
    @fastly.delete_service(service)
  end
end
