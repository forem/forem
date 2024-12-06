# frozen_string_literal: true

$: << File.dirname(__FILE__)
$oj_dir = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))
%w(lib ext).each do |dir|
  $: << File.join($oj_dir, dir)
end

require 'test/unit'
REAL_JSON_GEM = !!ENV['REAL_JSON_GEM']

if ENV['REAL_JSON_GEM']
  require 'json'
else
  require 'oj'
  Oj.mimic_JSON

  # This method was added in Ruby 3.0.0. Calling it this way asks the GC to
  # move objects around, helping to find object movement bugs.
  if defined?(GC.verify_compaction_references) == 'method'
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2.0")
      GC.verify_compaction_references(expand_heap: true, toward: :empty)
    else
      GC.verify_compaction_references(double_heap: true, toward: :empty)
    end
  end
end

NaN = JSON::NaN if defined?(JSON::NaN)
NaN = 0.0/0 unless defined?(NaN)
