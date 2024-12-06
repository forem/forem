# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
#
# Running specs from the command line:
#   $ rake spec                   # Entire spec suite.
#   $ rspec spec/objects_spec.rb  # Individual spec file.
#
# NOTE: To successfully run specs with Ruby 1.8.6 the older versions of
# Bundler and RSpec gems are required:
#
# $ gem install bundler -v=1.0.2
# $ gem install rspec -v=2.6.0
#

# require 'simplecov'
# SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each do |file|
  require file
end

ExtVerifier.require_dependencies!(
  %w[
    rails
    active_record
    action_controller
    action_view
    active_support/all
    mongoid
    mongo_mapper
    ripple nobrainer
    ostruct
    sequel
  ]
)
require 'nokogiri' unless RUBY_PLATFORM.include?('mswin')
require 'amazing_print'

RSpec.configure do |config|
  config.disable_monkey_patching!
  # TODO: Make specs not order dependent
  # config.order = :random
  Kernel.srand config.seed
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  # Run before all examples. Using suite or all will not work as stubs are
  # killed after each example ends.
  config.before do |_example|
    stub_dotfile!
  end

  if RUBY_PLATFORM.include?('mswin')
    config.filter_run_excluding unix: true
  else
    config.filter_run_excluding mswin: true
  end
end

# This matcher handles the normalization of objects to replace non deterministic
# parts (such as object IDs) with simple placeholder strings before doing a
# comparison with a given string. It's important that this method only matches
# a string which strictly conforms to the expected object ID format.
RSpec::Matchers.define :be_similar_to do |expected, options|
  match do |actual|
    options ||= {}
    @actual = normalize_object_id_strings(actual, options)
    values_match? expected, @actual
  end

  diffable
end

# Override the Object IDs with a placeholder so that we are only checking
# that an ID is present and not that it matches a certain value. This is
# necessary as the Object IDs are not deterministic.
def normalize_object_id_strings(str, options)
  str = str.gsub(/#<(.*?):0x[a-f\d]+/, '#<\1:placeholder_id') unless options[:skip_standard]
  str = str.gsub(/BSON::ObjectId\('[a-f\d]{24}'\)/, 'placeholder_bson_id') unless options[:skip_bson]
  str
end

def stub_dotfile!
  allow_any_instance_of(AmazingPrint::Inspector)
    .to receive(:load_dotfile)
    .and_return(true)
end

def capture!
  standard = $stdout
  $stdout = StringIO.new
  yield
ensure
  $stdout = standard
end
