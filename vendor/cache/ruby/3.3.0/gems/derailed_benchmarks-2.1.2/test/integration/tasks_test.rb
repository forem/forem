# frozen_string_literal: true

require 'test_helper'
require 'shellwords'

class TasksTest < ActiveSupport::TestCase

  def setup
    FileUtils.mkdir_p(rails_app_path('tmp'))
  end

  def teardown
    FileUtils.remove_entry_secure(rails_app_path('tmp'))
  end

  def run!(cmd)
    puts "Running: #{cmd}"
    out = `#{cmd}`
    raise "Could not run #{cmd}, output: #{out}" unless $?.success?
    out
  end

  def rake(cmd, options = {})
    assert_success = options.key?(:assert_success) ? options[:assert_success] : true
    env             = options[:env]           || {}
    env_string = env.map {|key, value| "#{key.shellescape}=#{value.to_s.shellescape}" }.join(" ")
    cmd        = "env #{env_string} bundle exec rake -f perf.rake #{cmd} --trace"
    puts "Running: #{cmd}"
    result = Bundler.with_original_env { `cd '#{rails_app_path}' && #{cmd} 2>&1` }
    if assert_success && !$?.success?
      puts result
      raise "Expected '#{cmd}' to return a success status.\nOutput: #{result}"
    end

    result
  end

  test 'non-rails library with branch specified' do
    skip unless ENV['USING_RAILS_WICKED_BRANCH']

    gem_path = run!("bundle info wicked --path")
    env = { "TEST_COUNT" => 10, "DERAILED_SCRIPT_COUNT" => 2, "DERAILED_PATH_TO_LIBRARY" => gem_path}
    puts rake "perf:library", { env: env }
  end

  test 'rails perf:library from git' do
    # BUNDLE_GEMFILE="$(pwd)/gemfiles/rails_git.gemfile" bundle exec m test/integration/tasks_test.rb:<linenumber>

    skip unless ENV['USING_RAILS_GIT']

    env = { "TEST_COUNT" => 2, "DERAILED_SCRIPT_COUNT" => 2,
            "SHAS_TO_TEST" => "acb6631cd99cdfe7db356773ef74cad7cbb570ed,12bb9d32f56883914abcd98fd72e3c68c444808d"}
    puts rake "perf:library", { env: env }
  end

  test "rails perf:library with bad script" do
    # BUNDLE_GEMFILE="$(pwd)/gemfiles/rails_git.gemfile" bundle exec m test/integration/tasks_test.rb:<linenumber>

    skip unless ENV['USING_RAILS_GIT']

    error = assert_raises {
      env = { "DERAILED_SCRIPT" => "nopenopenop", "TEST_COUNT" => 2, "DERAILED_SCRIPT_COUNT" => 2,
              "SHAS_TO_TEST" => "acb6631cd99cdfe7db356773ef74cad7cbb570ed,12bb9d32f56883914abcd98fd72e3c68c444808d"}
      puts rake "perf:library", { env: env }
    }

    assert error.message =~ /nopenopenop:( command)? not found/, "Expected #{error.message} to include /nopenopenop: (command)? not found/ but it did not"
  end

  test 'hitting authenticated devise apps' do
    env = { "PATH_TO_HIT" => "authenticated", "USE_AUTH" => "true", "TEST_COUNT" => "2" }
    result = rake 'perf:test', env: env
    assert_match 'Auth: true', result

    env["USE_SERVER"] = "webrick"
    result = rake 'perf:test', env: env
    assert_match 'Auth: true',        result
    assert_match 'Server: "webrick"', result
  end

  test 'authenticate with a custom user' do
    env = { "AUTH_CUSTOM_USER" => "true", "PATH_TO_HIT" => "authenticated", "USE_AUTH" => "true", "TEST_COUNT" => "2" }
    result = rake 'perf:test', env: env
    assert_match 'Auth: true', result
  end

  test 'test' do
    rake "perf:test"
  end

  test 'app' do
    skip unless ENV['USING_RAILS_GIT']
    run!("cd #{rails_app_path} && git init . && git add . && git commit -m first && git commit --allow-empty -m second")
    env = { "TEST_COUNT" => 10, "DERAILED_SCRIPT_COUNT" => 2 }
    puts rake "perf:app", { env: env }
  end

  test 'TEST_COUNT' do
    result = rake "perf:test", env: { "TEST_COUNT" => 1 }
    assert_match "1 derailed requests", result
  end

  test 'WARM_COUNT' do
    result = rake "perf:test", env: { "WARM_COUNT" => 1 }
    assert_match "Warming up app:", result
  end

  test 'PATH_TO_HIT' do
    env    = { "PATH_TO_HIT" => 'foo', "TEST_COUNT" => "2" }
    result = rake "perf:test", env: env
    assert_match 'Endpoint: "foo"', result

    env["USE_SERVER"] = "webrick"
    result = rake "perf:test", env: env
    assert_match 'Endpoint: "foo"',   result
    assert_match 'Server: "webrick"', result
  end

  test 'HTTP headers' do
    env = {
      "PATH_TO_HIT" => 'foo_secret',
      "TEST_COUNT" => "2",
      "HTTP_AUTHORIZATION" => "Basic #{Base64.encode64("admin:secret")}",
      "HTTP_CACHE_CONTROL" => "no-cache"
    }
    result = rake "perf:test", env: env
    assert_match 'Endpoint: "foo_secret"', result
    assert_match 'HTTP headers: {"Authorization"=>"Basic YWRtaW46c2VjcmV0\n", "Cache-Control"=>"no-cache"}', result

    env["USE_SERVER"] = "webrick"
    result = rake "perf:test", env: env
    assert_match 'HTTP headers: {"Authorization"=>"Basic YWRtaW46c2VjcmV0\n", "Cache-Control"=>"no-cache"}', result
  end

  test 'USE_SERVER' do
    result = rake "perf:test", env: { "USE_SERVER" => 'webrick', "TEST_COUNT" => "2" }
    assert_match 'Server: "webrick"', result
  end

  test '' do
  end

  test 'objects' do
    rake "perf:objects"
  end

  test 'mem' do
    rake "perf:mem"
  end

  test 'mem_over_time' do
    rake "perf:mem_over_time"
  end

  test 'ips' do
    rake "perf:ips"
  end

  test 'heap_diff' do
    rake "perf:heap_diff", env: { "TEST_COUNT" => 5 }
  end
end
