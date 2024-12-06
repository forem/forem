require 'helper'

FROM = '2011-01-01 00:00:00'

# Testing client components related to stats
class StatsTest < Fastly::TestCase
  def setup
    opts = login_opts(:api_key)

    begin
      @fastly = Fastly.new(opts)
    rescue => e
      warn e.inspect
      warn e.backtrace.join("\n")
      exit(-1)
    end
  end

  def test_regions
    regions = @fastly.regions
    assert_equal true, (regions.size > 0)
  end

  def test_usage
    usage = @fastly.usage(:from => FROM)
    # usage can be and empty hash if no usage stats
    # this client is not responsiblew for verifying the stats api,
    # just that requests to stats work
    assert(usage)
    assert(usage['meta'])
    assert_equal 'success', usage['status']

    usage = @fastly.usage(:from => FROM, :by_month => 1)
    assert(usage)
    assert(usage['meta'])
    assert_equal 'success', usage['status']

    usage = @fastly.usage(:from => FROM, :by_service => 1)
    assert(usage)
    assert(usage['meta'])
    assert_equal 'success', usage['status']
  end

  def test_stats
    stats = @fastly.stats(:from => FROM)
    # stats can be and empty hash if no usage stats
    assert(stats)
    assert_equal 'success', stats['status']
    assert_equal 'all', stats['meta']['region']

    stats = @fastly.stats(:from => FROM, :field => 'requests')
    assert(stats)
    assert_equal 'success', stats['status']
    assert_equal 'all', stats['meta']['region']

    stats = @fastly.stats(:from => FROM, :aggregate => true)
    assert(stats)
    assert_equal 'success', stats['status']
    assert_equal 'all', stats['meta']['region']

    # stats aggregate with field
    assert_raises Fastly::Error do
      @fastly.stats(:from => FROM, :field => 'requests', :aggregate => true)
    end

    # stats aggregate with service
    assert_raises Fastly::Error do
      @fastly.stats(:from => FROM, :service => 'myserviceId', :aggregate => true)
    end

    assert_raises Fastly::Error do
      @fastly.stats(:from => FROM, :service => 'datServiceID', :field => 'requests', :aggregate => true)
    end
  end
end
