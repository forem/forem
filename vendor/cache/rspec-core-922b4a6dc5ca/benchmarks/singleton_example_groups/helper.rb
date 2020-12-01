require_relative "../../bundle/bundler/setup" # configures load paths
require 'rspec/core'
require 'stackprof'

class << RSpec
  attr_writer :world
end

RSpec::Core::Example.class_eval do
  alias_method :new_with_around_and_singleton_context_hooks, :with_around_and_singleton_context_hooks
  alias_method :old_with_around_and_singleton_context_hooks, :with_around_example_hooks
end

RSpec::Core::Hooks::HookCollections.class_eval do
  def old_register_global_singleton_context_hooks(*)
    # no-op: this method didn't exist before
  end
  alias_method :new_register_global_singleton_context_hooks, :register_global_singleton_context_hooks
end

RSpec::Core::Configuration.class_eval do
  def old_configure_example(*)
    # no-op: this method didn't exist before
  end
  alias_method :new_configure_example, :configure_example
end

RSpec.configure do |c|
  c.output_stream = StringIO.new
end

require 'benchmark/ips'

class BenchmarkHelpers
  def self.prepare_implementation(prefix)
    RSpec.world = RSpec::Core::World.new # clear our state
    RSpec::Core::Example.__send__ :alias_method, :with_around_and_singleton_context_hooks, :"#{prefix}_with_around_and_singleton_context_hooks"
    RSpec::Core::Hooks::HookCollections.__send__ :alias_method, :register_global_singleton_context_hooks, :"#{prefix}_register_global_singleton_context_hooks"
    RSpec::Core::Configuration.__send__ :alias_method, :configure_example, :"#{prefix}_configure_example"
  end

  @@runner = RSpec::Core::Runner.new(RSpec::Core::ConfigurationOptions.new([]))
  def self.define_and_run_examples(desc, count, group_meta: {}, example_meta: {})
    groups = count.times.map do |i|
      RSpec.describe "Group #{desc} #{i}", group_meta do
        10.times { |j| example("ex #{j}", example_meta) { } }
      end
    end

    @@runner.run_specs(groups)
  end

  def self.profile(count, meta = { example_meta: { apply_it: true } })
    [:new, :old].map do |prefix|
      prepare_implementation(prefix)

      results = StackProf.run(mode: :cpu) do
        define_and_run_examples("No match/#{prefix}", count, meta)
      end

      format_profile_results(results, prefix)
    end
  end

  def self.format_profile_results(results, prefix)
    File.open("tmp/#{prefix}_stack_prof_results.txt", "w") do |f|
      StackProf::Report.new(results).print_text(false, nil, f)
    end
    system "open tmp/#{prefix}_stack_prof_results.txt"

    File.open("tmp/#{prefix}_stack_prof_results.graphviz", "w") do |f|
      StackProf::Report.new(results).print_graphviz(nil, f)
    end

    system "dot tmp/#{prefix}_stack_prof_results.graphviz -Tpdf > tmp/#{prefix}_stack_prof_results.pdf"
    system "open tmp/#{prefix}_stack_prof_results.pdf"
  end

  def self.run_benchmarks
    Benchmark.ips do |x|
      implementations = { :old => "without", :new => "with" }
      # Historically, many of our benchmarks have initially been order-sensitive,
      # where whichever implementation went first got favored because defining
      # more groups (or whatever) would cause things to slow down. To easily
      # check if we're having those problems, you can pass REVERSE=1 to try
      # it out in the opposite order.
      implementations = implementations.to_a.reverse.to_h if ENV['REVERSE']

      implementations.each do |prefix, description|
        x.report("No match -- #{description} singleton group support") do |times|
          prepare_implementation(prefix)
          define_and_run_examples("No match/#{description}", times)
        end
      end

      implementations.each do |prefix, description|
        x.report("Example match -- #{description} singleton group support") do |times|
          prepare_implementation(prefix)
          define_and_run_examples("Example match/#{description}", times, example_meta: { apply_it: true })
        end
      end

      implementations.each do |prefix, description|
        x.report("Group match -- #{description} singleton group support") do |times|
          prepare_implementation(prefix)
          define_and_run_examples("Group match/#{description}", times, group_meta: { apply_it: true })
        end
      end

      implementations.each do |prefix, description|
        x.report("Both match -- #{description} singleton group support") do |times|
          prepare_implementation(prefix)
          define_and_run_examples("Both match/#{description}", times,
                                  example_meta: { apply_it: true },
                                  group_meta: { apply_it: true })
        end
      end
    end
  end
end
