$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'stackprof/middleware'
require 'minitest/autorun'
require 'tmpdir'

class StackProf::MiddlewareTest < Minitest::Test

  def test_path_default
    StackProf::Middleware.new(Object.new)

    assert_equal 'tmp/', StackProf::Middleware.path
  end

  def test_path_custom
    StackProf::Middleware.new(Object.new, { path: 'foo/' })

    assert_equal 'foo/', StackProf::Middleware.path
  end

  def test_save_default
    middleware = StackProf::Middleware.new(->(env) { 100.times { Object.new } },
                                          save_every: 1,
                                          enabled: true)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { middleware.call({}) }
      dir = File.join(dir, "tmp")
      assert File.directory? dir
      profile = Dir.entries(dir).reject { |x| File.directory?(x) }.first
      assert profile
      assert_equal "stackprof", profile.split("-")[0]
      assert_equal "cpu", profile.split("-")[1]
      assert_equal Process.pid.to_s, profile.split("-")[2]
    end
  end

  def test_save_custom
    middleware = StackProf::Middleware.new(->(env) { 100.times { Object.new } },
                                          path: "foo/",
                                          save_every: 1,
                                          enabled: true)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { middleware.call({}) }
      dir = File.join(dir, "foo")
      assert File.directory? dir
      profile = Dir.entries(dir).reject { |x| File.directory?(x) }.first
      assert profile
      assert_equal "stackprof", profile.split("-")[0]
      assert_equal "cpu", profile.split("-")[1]
      assert_equal Process.pid.to_s, profile.split("-")[2]
    end
  end

  def test_enabled_should_use_a_proc_if_passed
    env = {}

    StackProf::Middleware.new(Object.new, enabled: Proc.new{ false })
    refute StackProf::Middleware.enabled?(env)

    StackProf::Middleware.new(Object.new, enabled: Proc.new{ true })
    assert StackProf::Middleware.enabled?(env)
  end

  def test_enabled_should_use_a_proc_if_passed_and_use_the_request_env
    enable_proc = Proc.new {|env| env['PROFILE'] }

    env = Hash.new { false }
    StackProf::Middleware.new(Object.new, enabled: enable_proc)
    refute StackProf::Middleware.enabled?(env)

    env = Hash.new { true }
    StackProf::Middleware.new(Object.new, enabled: enable_proc)
    assert StackProf::Middleware.enabled?(env)
  end

  def test_raw
    StackProf::Middleware.new(Object.new, raw: true)
    assert StackProf::Middleware.raw
  end

  def test_metadata
    metadata = { key: 'value' }
    StackProf::Middleware.new(Object.new, metadata: metadata)
    assert_equal metadata, StackProf::Middleware.metadata
  end
end unless RUBY_ENGINE == 'truffleruby'
