#!/usr/bin/env ruby
#
# Copyright (c) 2006-2020 - R.W. van 't Veer

require 'test_helper'

class JPEGTest < TestCase
  def test_initialize
    all_test_jpegs.each do |fname|
      assert JPEG.new(fname)
      open(fname) { |rd| assert JPEG.new(rd) }
      assert JPEG.new(StringIO.new(File.read(fname)))
    end
  end

  def test_raises_malformed_jpeg
    begin
      JPEG.new(StringIO.new(""))
    rescue MalformedJPEG => ex
      assert ex
    end
    begin
      JPEG.new(StringIO.new("djibberish"))
    rescue MalformedJPEG => ex
      assert ex
    end
  end

  def test_size
    j = JPEG.new(f('image.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

    j = JPEG.new(f('exif.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

    j = JPEG.new(f('1x1.jpg'))
    assert_equal j.width, 1
    assert_equal j.height, 1
  end

  def test_comment
    assert_equal JPEG.new(f('image.jpg')).comment, "Here's a comment!"
  end

  def test_shutter_speed_value
    {
      'canon-g3.exif' => Rational(1, 1244),
      'Canon_PowerShot_A85.exif' => Rational(1, 806)
    }.each do |file, expected|
      assert_equal expected, TIFF.new(f(file)).shutter_speed_value
    end
  end

  def test_aperture_value
    {
      'canon-g3.exif' => 4.5,
      'Canon_PowerShot_A85.exif' => 2.8
    }.each do |file, expected|
      assert_equal expected, TIFF.new(f(file)).aperture_value
    end
  end

  def test_exif
    assert ! JPEG.new(f('image.jpg')).exif?
    assert JPEG.new(f('exif.jpg')).exif?
    assert JPEG.new(f('exif.jpg')).exif.date_time
    assert JPEG.new(f('exif.jpg')).exif.f_number
  end

  def test_to_hash
    h = JPEG.new(f('image.jpg')).to_hash
    assert_equal 100, h[:width]
    assert_equal 75, h[:height]
    assert_equal "Here's a comment!", h[:comment]

    h = JPEG.new(f('exif.jpg')).to_hash
    assert_equal 100, h[:width]
    assert_equal 75, h[:height]
    assert_kind_of Time, h[:date_time]
  end

  def test_exif_dispatch
    j = JPEG.new(f('exif.jpg'))
    assert JPEG.instance_methods.include?(:date_time)
    assert j.methods.include?(:date_time)
    assert j.respond_to?(:date_time)
    assert j.date_time
    assert_kind_of Time, j.date_time

    assert j.f_number
    assert_kind_of Rational, j.f_number
  end

  def test_no_method_error
    JPEG.new(f('image.jpg')).f_number

    begin
      JPEG.new(f('image.jpg')).foo
    rescue NoMethodError => ex
      assert ex
    end
  end

  def test_methods_method
    j = JPEG.new(f('exif.jpg'))
    assert j.methods.include?(:date_time)
    assert j.methods(true).include?(:date_time)
    assert ! j.methods(false).include?(:date_time)
  end

  def test_multiple_app1
    assert JPEG.new(f('multiple-app1.jpg')).exif?
  end

  def test_thumbnail
    count = 0
    all_test_jpegs.each do |fname|
      jpeg = JPEG.new(fname)
      unless jpeg.thumbnail.nil?
        assert JPEG.new(StringIO.new(jpeg.thumbnail))
        count += 1
      end
    end

    assert count > 0, 'no thumbnails found'
  end

  def test_skippable_thumbnail
    all_test_jpegs.each do |fname|
      jpeg = JPEG.new(fname, load_thumbnails: false)
      assert jpeg.thumbnail.nil?
    end
  end

  def test_gps_with_altitude
    t = JPEG.new(f('gps-altitude.jpg'))

    assert_equal([Rational(230, 1), Rational(0, 1), Rational(0, 1)], t.gps_altitude)
    assert_equal(230, t.gps.altitude)
  end

  def test_exif_datetime_milliseconds
    if Time.now.strftime('%L') == '%L'
      STDERR.puts("skipping milliseconds test; not supported on this platform")
      return
    end

    j = JPEG.new(f('exif.jpg'))
    assert_equal('000', j.date_time.strftime('%L'))
    assert_equal('000', j.date_time_original.strftime('%L'))
    assert_equal('000', j.date_time_digitized.strftime('%L'))

    j = JPEG.new(f('ios-mspix-milliseconds.jpg'))
    assert_equal('978', j.date_time.strftime('%L'))
    assert_equal('978', j.date_time_original.strftime('%L'))
    assert_equal('978', j.date_time_digitized.strftime('%L'))
  end

end
