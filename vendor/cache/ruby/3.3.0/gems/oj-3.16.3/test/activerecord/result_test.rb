#!/usr/bin/env ruby

$: << File.dirname(__FILE__)
$: << File.dirname(File.dirname(__FILE__))

require 'helper'
require "rails/all"

Oj::Rails.set_encoder()
Oj::Rails.optimize()

Oj.default_options = { mode: :rails }

class ActiveRecordResultTest < Minitest::Test
  def test_hash_rows
    result = ActiveRecord::Result.new(["one", "two"],
                                      [
                                        ["row 1 col 1", "row 1 col 2"],
                                        ["row 2 col 1", "row 2 col 2"],
                                        ["row 3 col 1", "row 3 col 2"],
                                      ])
    #puts "*** result: #{Oj.dump(result, indent: 2)}"
    json_result = if ActiveRecord.version >= Gem::Version.new("6")
                    result.to_a
                  else
                    result.to_hash
                  end

    assert_equal Oj.dump(result, mode: :rails), Oj.dump(json_result)
  end
end
