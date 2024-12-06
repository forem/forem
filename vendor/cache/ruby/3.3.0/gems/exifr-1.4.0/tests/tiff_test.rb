#!/usr/bin/env ruby
#
# Copyright (c) 2006-2020 - R.W. van 't Veer

require 'test_helper'

class TIFFTest < TestCase
  def setup
    @t = TIFF.new(f('nikon_d1x.tif'))
  end

  def test_initialize
    all_test_tiffs.each do |fname|
      assert TIFF.new(fname)
      open(fname) { |rd| assert TIFF.new(rd) }
      assert TIFF.new(StringIO.new(File.read(fname)))
    end
  end

  def test_raises_malformed_tiff
    begin
      TIFF.new(StringIO.new("djibberish"))
    rescue MalformedTIFF => ex
      assert ex
    end
  end

  def test_multiple_images
    assert_equal(2, @t.size)
  end

  def test_size
    assert_equal(269, @t.image_width)
    assert_equal(269, @t.image_length)
    assert_equal(269, @t.width)
    assert_equal(269, @t.height)
    assert_equal(120, @t[1].image_width)
    assert_equal(160, @t[1].image_length)
    assert_equal(120, @t[1].width)
    assert_equal(160, @t[1].height)

    @t = TIFF.new(f('plain.tif'))
    assert_equal(23, @t.image_width)
    assert_equal(24, @t.image_length)
    assert_equal(23, @t.width)
    assert_equal(24, @t.height)
  end

  def test_enumerable
    assert_equal(@t[1], @t.find { |i| i.f_number.nil? })
  end

  def test_misc_fields
    assert_equal('Canon PowerShot G3', TIFF.new(f('canon-g3.exif')).model)
  end

  def test_dates
    (all_test_tiffs - [f('weird_date.exif'), f('plain.tif'), f('endless-loop.exif'), f('truncated.exif')]).each do |fname|
      assert_kind_of Time, TIFF.new(fname).date_time
    end
    assert_nil TIFF.new(f('weird_date.exif')).date_time
  end

  def test_time_with_zone
    old_proc = TIFF.mktime_proc
    TIFF.mktime_proc = proc { |*args| "TIME-WITH-ZONE" }
    assert_equal "TIME-WITH-ZONE", TIFF.new(f('nikon_d1x.tif')).date_time
  ensure
    TIFF.mktime_proc = old_proc
  end

  def test_orientation
    tested = 0 # count tests because not all exif samples have an orientation field
    all_test_exifs.each do |fname|
      orientation = TIFF.new(fname).orientation
      if orientation
        assert [
          TIFF::TopLeftOrientation,
          TIFF::TopRightOrientation,
          TIFF::BottomRightOrientation,
          TIFF::BottomLeftOrientation,
          TIFF::LeftTopOrientation,
          TIFF::RightTopOrientation,
          TIFF::RightBottomOrientation,
          TIFF::LeftBottomOrientation
        ].any? { |c| orientation == c }, 'not an orientation'
        assert [
          :TopLeft,
          :TopRight,
          :BottomRight,
          :BottomLeft,
          :LeftTop,
          :RightTop,
          :RightBottom,
          :LeftBottom
        ].any? { |c| orientation.to_sym == c }, 'not an orientation symbol'
        assert orientation.respond_to?(:to_i)
        assert orientation.respond_to?(:transform_rmagick)
        tested += 1
      end
    end
    assert tested > 0
  end

  def test_gps
    t = TIFF.new(f('gps.exif'))
    assert_equal("\2\2\0\0", t.gps_version_id)
    assert_equal('N', t.gps_latitude_ref)
    assert_equal('W', t.gps_longitude_ref)
    assert_equal([5355537.quo(100000), 0.quo(1), 0.quo(1)], t.gps_latitude)
    assert_equal([678886.quo(100000), 0.quo(1), 0.quo(1)], t.gps_longitude)
    assert_equal('WGS84', t.gps_map_datum)
    assert_equal(54, t.gps.latitude.round)
    assert_equal(-7, t.gps.longitude.round)
    assert_nil(t.gps.altitude)

    (all_test_exifs - %w(gps user-comment out-of-range negative-exposure-bias-value).map{|v| f("#{v}.exif")}).each do |fname|
      assert_nil TIFF.new(fname).gps_version_id
    end
  end

  def test_bad_gps
    assert_nil TIFF.new(f('bad_gps.exif')).gps
  end

  def test_lens_model
    t = TIFF.new(f('sony-a7ii.exif'))
    assert_equal('FE 16-35mm F4 ZA OSS', t.lens_model)
  end

  def test_ifd_dispatch
    assert @t.respond_to?(:f_number)
    assert @t.methods.include?(:f_number)
    assert TIFF.instance_methods.include?(:f_number)

    assert @t.f_number
    assert_kind_of Rational, @t.f_number
    assert @t[0].f_number
    assert_kind_of Rational, @t[0].f_number
  end

  def test_avoid_dispatch_to_nonexistent_ifds
    all_test_tiffs.each do |fname|
      assert t = TIFF.new(fname)
      assert TIFF::TAGS.map { |tag| t.send(tag) }
    end
  end

  def test_to_hash
    all_test_tiffs.each do |fname|
      t = TIFF.new(fname)
      TIFF::TAGS.each do |key|
        assert_literally_equal t.send(key), t.to_hash[key.to_sym], "#{key} not equal"
      end
    end
  end

  def test_old_style
    assert @t[:f_number]
  end

  def test_yaml_dump_and_load
    require 'yaml'

    all_test_tiffs.each do |fname|
      t = TIFF.new(fname)
      y = YAML.dump(t)
      v = if YAML.respond_to?(:unsafe_load)
            YAML.unsafe_load(y)
          else
            YAML.load(y)
          end
      assert_literally_equal t.to_hash, v.to_hash
    end
  end

  def test_jpeg_thumbnails
    count = 0
    all_test_tiffs.each do |fname|
      t = TIFF.new(fname)
      unless t.jpeg_thumbnails.empty?
        t.jpeg_thumbnails.each do |n|
          assert JPEG.new(StringIO.new(n))
        end
        count += 1
      end
    end
    assert count > 0, 'no thumbnails found'
  end

  def test_skippable_jpeg_thumbnails
    all_test_tiffs.each do |fname|
      t = TIFF.new(fname, load_thumbnails: false)
      assert t.jpeg_thumbnails.empty?
    end
  end

  def test_should_not_loop_endlessly
    TIFF.new(f('endless-loop.exif'))
    assert true
  end

  def test_should_read_truncated
    TIFF.new(f('truncated.exif'))
    assert true
  end

  def test_user_comment
    assert_equal("Manassas Battlefield", TIFF.new(f('user-comment.exif')).user_comment)
  end

  def test_handle_out_of_range_offset
    assert_equal 'NIKON', TIFF.new(f('out-of-range.exif')).make
  end

  def test_negative_exposure_bias_value
    assert_equal(-1.quo(3), TIFF.new(f('negative-exposure-bias-value.exif')).exposure_bias_value)
  end

  def test_nul_terminated_strings
    assert_equal 'GoPro', TIFF.new(f('gopro_hd2.exif')).make
  end

  def test_methods_method
    t = TIFF.new(f('gopro_hd2.exif'))
    assert t.methods.include?(:make)
    assert t.methods(true).include?(:make)
    assert ! t.methods(false).include?(:make)
  end

  def test_unknow_field
    assert_equal [1, 1, 1, 1], TIFF.new(f('plain.tif')).first.raw_fields[0x0153] # TIFF Tag SampleFormat
  end
end
