#!/usr/bin/env ruby
# frozen_string_literal: true

# This is a benchmark for HTTPS traffic.
# To run against a local server:
# docker run --rm --detach --name httpbin -v /tmp:/tmp -v $PWD/tests/data:/data -e HTTPS_CERT_FILE='/data/127.0.0.1.cert.crt' -e HTTPS_KEY_FILE='/data/127.0.0.1.cert.key' -e PORT='8443' -p 8443:8443 mccutchen/go-httpbin
# Then, run the benchmark:
# benchmarks/httpbin.rb --uri='https://localhost:8443/stream-bytes/102400?chunk_size=1024'
# Finally, stop the server with:
# docker kill httpbin

#require 'bundler/inline'

#gemfile do
# source 'https://rubygems.org'

# gem 'benchmark-ips', require: 'benchmark/ips'
  #  gem 'ruby-prof', '1.6.3'
# gem 'excon'
#end

require File.expand_path('../test_helper', __FILE__)


require 'openssl'
require 'optparse'
require 'uri'
require 'excon'
require 'benchmark'
require 'benchmark/ips'

Options = Struct.new(:uri, :profile, :time, :warmup, :iterations, :status)

options = Options.new(
  URI.parse('https://httpbingo.org/stream-bytes/102400?chunk_size=1024'),
  false,
  10,
  5,
  2,
  200
)

OptionParser.new do |opts|
  opts.banner = "Usage: ruby #{__FILE__} [options]"

  opts.on('-u URI', '--uri=URI', String, "URI to send requests to (default: #{options.uri})") do |uri|
    options.uri = URI.parse(uri)
  end

  opts.on('-p', '--[no-]profile', 'Profile the benchmark using Ruby-Prof (defaults to no profiling)') do |profile|
    options.profile = profile
  end

  opts.on('-t TIME', '--time=TIME', Float, "The number of seconds to run the benchmark to measure performance (default: #{options.time})") do |time|
    options.time = time
  end

  opts.on('-w WARMUP', '--warmup=WARMUP', Float, "The number of seconds to warmup the benchmark for before measuring (default: #{options.warmup})") do |warmup|
    options.warmup = warmup
  end

  opts.on('-i ITERATIONS', '--iterations=ITERATIONS', Integer, "The number of iterations to run the benchmark for (default: #{options.iterations})") do |iterations|
    options.iterations = iterations
  end

  opts.on('-s STATUS', '--status=STATUS', Integer, "The HTTP status expected from a request to the given URI (default: #{options.status})") do |status|
    options.status = status
  end

  opts.on('-h', '--help', 'print options') do
    puts opts
    exit
  end
end.parse!

# Enable and start GC before each job run. Disable GC afterwards.
#
# Inspired by https://www.omniref.com/ruby/2.2.1/symbols/Benchmark/bm?#annotation=4095926&line=182
class GCSuite
  def warming(*)
    run_gc
  end

  def running(*)
    run_gc
  end

  def warmup_stats(*); end

  def add_report(*); end

  private

  def run_gc
    GC.enable
    GC.start
    GC.compact
    GC.disable
  end
end

profile = nil

if options.profile
  profile = RubyProf::Profile.new(track_allocations: true, measure_mode: RubyProf::MEMORY)
  profile.start
  profile.pause
end

excerpt = ['Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.']
data = (excerpt * 3).join(' ')

client = ::Excon.new(options.uri.to_s, ssl_verify_peer: false, ssl_verify_peer_host: false, persistent: true, retry_errors: [Excon::Error::Socket], idempotent: true)

Benchmark.ips do |x|
  x.time = options.time
  x.warmup = options.warmup
  x.suite = GCSuite.new
  x.iterations = options.iterations

  x.report(options.uri.to_s) do
    profile&.resume

    response = client.request(method: :get, headers: { data: data })

    response.body
    response.status

    profile&.pause

    raise "Invalid status: expected #{options.status}, actual is #{response.status}" unless response.status == options.status
  end

  x.compare!
end

if options.profile
  result = profile.stop

  File.open("excon-#{Excon::VERSION}.html", 'w') do |output|
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(output)
  end
end