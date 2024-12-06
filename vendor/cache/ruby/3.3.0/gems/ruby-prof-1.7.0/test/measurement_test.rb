# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)

class MeasurementTest < Minitest::Test
  def test_initialize
    measurement = RubyProf::Measurement.new(3.3, 2.2, 1.1, 4)
    assert_equal(3.3, measurement.total_time)
    assert_equal(2.2, measurement.self_time)
    assert_equal(1.1, measurement.wait_time)
    assert_equal(4, measurement.called)
  end

  def test_clone
    measurement_1 = RubyProf::Measurement.new(3.3, 2.2, 1.1, 4)
    measurement_2 = measurement_1.clone

    refute(measurement_1.equal?(measurement_2))
    refute(measurement_1.eql?(measurement_2))
    refute(measurement_1 == measurement_2)

    assert_equal(measurement_1.total_time, measurement_2.total_time)
    assert_equal(measurement_1.self_time, measurement_2.self_time)
    assert_equal(measurement_1.wait_time, measurement_2.wait_time)
    assert_equal(measurement_1.called, measurement_2.called)
  end

  def test_dup
    measurement_1 = RubyProf::Measurement.new(3.3, 2.2, 1.1, 4)
    measurement_2 = measurement_1.dup

    refute(measurement_1.equal?(measurement_2))
    refute(measurement_1.eql?(measurement_2))
    refute(measurement_1 == measurement_2)

    assert_equal(measurement_1.total_time, measurement_2.total_time)
    assert_equal(measurement_1.self_time, measurement_2.self_time)
    assert_equal(measurement_1.wait_time, measurement_2.wait_time)
    assert_equal(measurement_1.called, measurement_2.called)
  end

  def test_merge!
    measurement1 = RubyProf::Measurement.new(3.3, 2.2, 1.1, 4)
    measurement2 = RubyProf::Measurement.new(3, 2, 1, 3)

    measurement1.merge!(measurement2)

    assert_equal(6.3, measurement1.total_time)
    assert_equal(4.2, measurement1.self_time)
    assert_equal(2.1, measurement1.wait_time)
    assert_equal(7, measurement1.called)

    assert_equal(3, measurement2.total_time)
    assert_equal(2, measurement2.self_time)
    assert_equal(1, measurement2.wait_time)
    assert_equal(3, measurement2.called)
  end

  def test_set_total_time
    measurement = RubyProf::Measurement.new(4, 3, 1, 1)
    measurement.total_time = 5.1
    assert_equal(5.1, measurement.total_time)
  end

  def test_set_self_time
    measurement = RubyProf::Measurement.new(4, 3, 1, 1)
    measurement.self_time = 3.1
    assert_equal(3.1, measurement.self_time)
  end

  def test_set_wait_time
    measurement = RubyProf::Measurement.new(4, 3, 1, 1)
    measurement.wait_time = 1.1
    assert_equal(1.1, measurement.wait_time)
  end

  def test_set_called
    measurement = RubyProf::Measurement.new(4, 3, 1, 1)
    measurement.called = 2
    assert_equal(2, measurement.called)
  end
end
