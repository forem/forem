#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class ExceptionsTest < TestCase
  def test_profile
    result = begin
      RubyProf::Profile.profile do
        raise(RuntimeError, 'Test error')
      end
    rescue
    end
    assert_kind_of(RubyProf::Profile, result)
  end

  def test_profile_allows_exceptions
    assert_raises(RuntimeError) do
      RubyProf::Profile.profile(:allow_exceptions => true) do
        raise(RuntimeError, 'Test error')
      end
    end
  end
end
