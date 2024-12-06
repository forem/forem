#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__
$LOAD_PATH << File.join(__dir__, 'json_gem')

require 'json_common_interface_test'
require 'json_encoding_test'
require 'json_ext_parser_test'
require 'json_fixtures_test'
require 'json_generator_test'
require 'json_generic_object_test'
require 'json_parser_test'
require 'json_string_matching_test'

at_exit do
  require 'helper'
  if '3.1.0' <= RUBY_VERSION && RbConfig::CONFIG['host_os'] !~ /(mingw|mswin)/
    # Oj::debug_odd("teardown before GC.verify_compaction_references")
    verify_gc_compaction
    # Oj::debug_odd("teardown after GC.verify_compaction_references")
  end
end
