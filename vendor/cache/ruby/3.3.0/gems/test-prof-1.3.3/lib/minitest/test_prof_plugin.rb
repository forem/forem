# frozen_string_literal: true

require "test_prof/event_prof/minitest"
require "test_prof/factory_doctor/minitest"
require "test_prof/memory_prof/minitest"
require "test_prof/tag_prof/minitest"

module Minitest # :nodoc:
  module TestProf # :nodoc:
    def self.configure_options(options = {})
      options.tap do |opts|
        opts[:event] = ENV["EVENT_PROF"] if ENV["EVENT_PROF"]
        opts[:rank_by] = ENV["EVENT_PROF_RANK"].to_sym if ENV["EVENT_PROF_RANK"]
        opts[:top_count] = ENV["EVENT_PROF_TOP"].to_i if ENV["EVENT_PROF_TOP"]
        opts[:per_example] = true if ENV["EVENT_PROF_EXAMPLES"]
        opts[:fdoc] = true if ENV["FDOC"]
        opts[:sample] = true if ENV["SAMPLE"] || ENV["SAMPLE_GROUPS"]
        opts[:mem_prof_mode] = ENV["TEST_MEM_PROF"] if ENV["TEST_MEM_PROF"]
        opts[:mem_prof_top_count] = ENV["TEST_MEM_PROF_COUNT"] if ENV["TEST_MEM_PROF_COUNT"]
        opts[:tag_prof] = true if ENV["TAG_PROF"] == "type"
      end
    end
  end

  def self.plugin_test_prof_options(opts, options)
    opts.on "--event-prof=EVENT", "Collects metrics for specified EVENT" do |event|
      options[:event] = event
    end
    opts.on "--event-prof-rank-by=RANK_BY", "Defines RANK_BY parameter for results" do |rank|
      options[:rank_by] = rank.to_sym
    end
    opts.on "--event-prof-top-count=N", "Limits results with N groups/examples" do |count|
      options[:top_count] = count.to_i
    end
    opts.on "--event-prof-per-example", TrueClass, "Includes examples metrics to results" do |flag|
      options[:per_example] = flag
    end
    opts.on "--factory-doctor", TrueClass, "Enable Factory Doctor for your examples" do |flag|
      options[:fdoc] = flag
    end
    opts.on "--mem-prof=MODE", "Enable MemoryProf for your examples" do |flag|
      options[:mem_prof_mode] = flag
    end
    opts.on "--mem-prof-top-count=N", "Limits MemoryProf results with N groups/examples" do |flag|
      options[:mem_prof_top_count] = flag
    end
  end

  def self.plugin_test_prof_init(options)
    options = TestProf.configure_options(options)

    reporter << TestProf::EventProfReporter.new(options[:io], options) if options[:event]
    reporter << TestProf::FactoryDoctorReporter.new(options[:io], options) if options[:fdoc]
    reporter << TestProf::MemoryProfReporter.new(options[:io], options) if options[:mem_prof_mode]
    reporter << Minitest::TestProf::TagProfReporter.new(options[:io], options) if options[:tag_prof]

    ::TestProf::MinitestSample.call if options[:sample]
  end
end
