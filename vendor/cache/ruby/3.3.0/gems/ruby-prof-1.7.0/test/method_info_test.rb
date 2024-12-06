# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)
require 'base64'

class MethodInfoTest < Minitest::Test
  def test_initialize
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal("Base64", method_info.klass_name)
    assert_equal(:encode64, method_info.method_name)
    assert_equal("Base64#encode64", method_info.full_name)
    assert_equal(0, method_info.klass_flags)
    assert_match(/base64\.rb/, method_info.source_file)
    assert_kind_of(Integer, method_info.line)
    refute(method_info.recursive?)

    assert_kind_of(RubyProf::Measurement, method_info.measurement)
    assert_kind_of(RubyProf::CallTrees, method_info.call_trees)
    assert_empty(method_info.allocations)
  end

  def test_initialize_nil_klass
    error = assert_raises(NoMethodError) do
      RubyProf::MethodInfo.new(nil, nil)
    end
    assert_match(/undefined method `instance_method' for nil/, error.message)
  end

  def test_initialize_nil_method_name
    error = assert_raises(TypeError) do
      RubyProf::MethodInfo.new(Base64, nil)
    end
    assert_equal("nil is not a symbol nor a string", error.to_s)
  end

  def test_initialize_unknown_location
    method_info = RubyProf::MethodInfo.new(Array, :size)
    assert_equal('Array', method_info.klass_name)
    assert_equal(:size, method_info.method_name)
    assert_nil(method_info.source_file)
    assert_equal(0, method_info.line)
  end

  def test_measurement
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal(0, method_info.total_time)
    assert_equal(0, method_info.self_time)
    assert_equal(0, method_info.wait_time)
    assert_equal(0, method_info.children_time)
    assert_equal(0, method_info.called)
  end

  def test_compare
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal(0, method_info_1 <=> method_info_2)

    method_info_1 = RubyProf::MethodInfo.new(Base64, :decode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal(-1, method_info_1 <=> method_info_2)

    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :decode64)
    assert_equal(1, method_info_1 <=> method_info_2)
  end

  def test_eql?
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    assert(method_info_1.eql?(method_info_2))
  end

  def test_equal?
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    refute(method_info_1.equal?(method_info_2))
  end

  def test_equality
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    assert(method_info_1 == method_info_2)
  end

  def test_hash
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal(method_info_1.hash, method_info_2.hash)
  end

  def test_to_s
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    assert_equal("Base64#encode64 (c: 0, tt: 0.0, st: 0.0, wt: 0.0, ct: 0.0)", method_info.to_s)
  end
end
