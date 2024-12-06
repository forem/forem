require 'common'
require 'fastly'
require 'minitest/autorun'
require 'pry'
require 'dotenv/load'

class Fastly
  class TestCase < Minitest::Test; end
end

def login_opts(mode = :full)
  opts = {}
  [:url, :port].each do |what|
    key = "FASTLY_TEST_BASE_#{what.to_s.upcase}"
    opts["base_#{what}".to_sym] = ENV[key] if ENV.key?(key)
  end

  required = case mode
             when :full
               [:user, :password]
             when :both
               [:user, :password, :api_key]
             else
               [:api_key]
             end

  required.each do |what|
    key = "FASTLY_TEST_#{what.to_s.upcase}"
    unless ENV.key?(key)
      warn "You haven't set the environment variable #{key}"
      exit(-1)
    end
    opts[what] = ENV[key]
  end
  opts
end

def random_string
  "#{Process.pid}-#{Time.now.to_i}-#{Kernel.rand(1000)}"
end
