# frozen_string_literal: true

require 'objspace'
module MemoryProfiler
  # Reporter is the top level API used for generating memory reports.
  #
  # @example Measure object allocation in a block
  #   report = Reporter.report(top: 50) do
  #     5.times { "foo" }
  #   end
  class Reporter
    class << self
      attr_accessor :current_reporter
    end

    attr_reader :top, :trace, :generation, :report_results

    def initialize(opts = {})
      @top          = opts[:top] || 50
      @trace        = opts[:trace] && Array(opts[:trace])
      @ignore_files = opts[:ignore_files] && Regexp.new(opts[:ignore_files])
      @allow_files  = opts[:allow_files] && /#{Array(opts[:allow_files]).join('|')}/
    end

    # Helper for generating new reporter and running against block.
    # @param [Hash] opts the options to create a report with
    # @option opts :top max number of entries to output
    # @option opts :trace a class or an array of classes you explicitly want to trace
    # @option opts :ignore_files a regular expression used to exclude certain files from tracing
    # @option opts :allow_files a string or array of strings to selectively include in tracing
    # @return [MemoryProfiler::Results]
    def self.report(opts = {}, &block)
      self.new(opts).run(&block)
    end

    def start
      3.times { GC.start }
      GC.start
      GC.disable

      @generation = GC.count
      ObjectSpace.trace_object_allocations_start
    end

    def stop
      ObjectSpace.trace_object_allocations_stop
      allocated = object_list(generation)
      retained = StatHash.new.compare_by_identity

      GC.enable
      # for whatever reason doing GC in a block is more effective at
      # freeing objects.
      # full_mark: true, immediate_mark: true, immediate_sweep: true are already default
      3.times { GC.start }
      # another start outside of the block to release the block
      GC.start

      # Caution: Do not allocate any new Objects between the call to GC.start and the completion of the retained
      #          lookups. It is likely that a new Object would reuse an object_id from a GC'd object.

      ObjectSpace.each_object do |obj|
        next unless ObjectSpace.allocation_generation(obj) == generation
        found = allocated[obj.__id__]
        retained[obj.__id__] = found if found
      end
      ObjectSpace.trace_object_allocations_clear

      @report_results = Results.new
      @report_results.register_results(allocated, retained, top)
    end

    # Collects object allocation and memory of ruby code inside of passed block.
    def run(&block)
      start
      begin
        yield
      rescue Exception
        ObjectSpace.trace_object_allocations_stop
        GC.enable
        raise
      else
        stop
      end
    end

    private

    # Iterates through objects in memory of a given generation.
    # Stores results along with meta data of objects collected.
    def object_list(generation)
      helper = Helpers.new

      result = StatHash.new.compare_by_identity

      ObjectSpace.each_object do |obj|
        next unless ObjectSpace.allocation_generation(obj) == generation

        file = ObjectSpace.allocation_sourcefile(obj) || "(no name)"
        next if @ignore_files && @ignore_files =~ file
        next if @allow_files && !(@allow_files =~ file)

        klass = helper.object_class(obj)
        next if @trace && !trace.include?(klass)

        begin
          line       = ObjectSpace.allocation_sourceline(obj)
          location   = helper.lookup_location(file, line)
          class_name = helper.lookup_class_name(klass)
          gem        = helper.guess_gem(file)

          # we do memsize first to avoid freezing as a side effect and shifting
          # storage to the new frozen string, this happens on @hash[s] in lookup_string
          memsize = ObjectSpace.memsize_of(obj)
          string = klass == String ? helper.lookup_string(obj) : nil

          # compensate for API bug
          memsize = GC::INTERNAL_CONSTANTS[:RVALUE_SIZE] if memsize > 100_000_000_000
          result[obj.__id__] = MemoryProfiler::Stat.new(class_name, gem, file, location, memsize, string)
        rescue
          # give up if any any error occurs inspecting the object
        end
      end

      result
    end
  end
end
