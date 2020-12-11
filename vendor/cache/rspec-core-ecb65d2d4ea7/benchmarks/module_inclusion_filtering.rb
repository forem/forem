require_relative "../bundle/bundler/setup" # configures load paths
require 'rspec/core'

class << RSpec
  attr_writer :world
end

# Here we are restoring the old implementation of `configure_group`, so that
# we can toggle the new vs old implementation in the benchmark by aliasing it.
module RSpecConfigurationOverrides
  def initialize(*args)
    super
    @include_extend_or_prepend_modules = []
  end

  def include(mod, *filters)
    meta = RSpec::Core::Metadata.build_hash_from(filters, :warn_about_example_group_filtering)
    @include_extend_or_prepend_modules << [:include, mod, meta]
    super
  end

  def old_configure_group(group)
    @include_extend_or_prepend_modules.each do |include_extend_or_prepend, mod, filters|
      next unless filters.empty? || RSpec::Core::MetadataFilter.apply?(:any?, filters, group.metadata)
      __send__("safe_#{include_extend_or_prepend}", mod, group)
    end
  end

  def self.prepare_implementation(prefix)
    RSpec.world = RSpec::Core::World.new # clear our state
    RSpec::Core::Configuration.class_eval do
      alias_method :configure_group, :"#{prefix}_configure_group"
    end
  end
end

RSpec::Core::Configuration.class_eval do
  prepend RSpecConfigurationOverrides
  alias new_configure_group configure_group
end

RSpec.configure do |c|
  50.times { c.include Module.new, :include_it }
end

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("Old linear search: non-matching metadata") do |times|
    RSpecConfigurationOverrides.prepare_implementation(:old)
    times.times { |i| RSpec.describe "Old linear search: non-matching metadata #{i}" }
  end

  x.report("New memoized search: non-matching metadata") do |times|
    RSpecConfigurationOverrides.prepare_implementation(:new)
    times.times { |i| RSpec.describe "New memoized search: non-matching metadata #{i}" }
  end

  x.report("Old linear search: matching metadata") do |times|
    RSpecConfigurationOverrides.prepare_implementation(:old)
    times.times { |i| RSpec.describe "Old linear search: matching metadata #{i}", :include_it }
  end

  x.report("New memoized search: matching metadata") do |times|
    RSpecConfigurationOverrides.prepare_implementation(:new)
    times.times { |i| RSpec.describe "New memoized search: matching metadata #{i}", :include_it }
  end
end

__END__

Calculating -------------------------------------
Old linear search: non-matching metadata
                        86.000  i/100ms
New memoized search: non-matching metadata
                        93.000  i/100ms
Old linear search: matching metadata
                        79.000  i/100ms
New memoized search: matching metadata
                        90.000  i/100ms
-------------------------------------------------
Old linear search: non-matching metadata
                        884.109  (±61.9%) i/s -      3.268k
New memoized search: non-matching metadata
                          1.099k (±81.2%) i/s -      3.441k
Old linear search: matching metadata
                        822.348  (±57.5%) i/s -      3.081k
New memoized search: matching metadata
                          1.116k (±76.6%) i/s -      3.510k
