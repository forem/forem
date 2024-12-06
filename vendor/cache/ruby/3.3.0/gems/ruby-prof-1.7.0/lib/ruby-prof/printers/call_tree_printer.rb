# encoding: utf-8

require 'fiber'
require 'thread'
require 'fileutils'

module RubyProf
  # Generates profiling information in callgrind format for use by
  # kcachegrind and similar tools.

  class CallTreePrinter < AbstractPrinter
    def calltree_name(method_info)
      klass_path = method_info.klass_name.gsub("::", '/')
      result = "#{klass_path}::#{method_info.method_name}"

      case method_info.klass_flags
        when 0x2
          "#{result}^"
        when 0x4
          "#{result}^"
        when 0x8
         "#{result}*"
        else
         result
      end
    end

    def determine_event_specification_and_value_scale
      @event_specification = "events: "
      case @result.measure_mode
        when RubyProf::PROCESS_TIME
          @value_scale = RubyProf::CLOCKS_PER_SEC
          @event_specification << 'process_time'
        when RubyProf::WALL_TIME
          @value_scale = 1_000_000
          @event_specification << 'wall_time'
        when RubyProf.const_defined?(:ALLOCATIONS) && RubyProf::ALLOCATIONS
          @value_scale = 1
          @event_specification << 'allocations'
        when RubyProf.const_defined?(:MEMORY) && RubyProf::MEMORY
          @value_scale = 1
          @event_specification << 'memory'
        when RubyProf.const_defined?(:GC_RUNS) && RubyProf::GC_RUNS
          @value_scale = 1
          @event_specification << 'gc_runs'
        when RubyProf.const_defined?(:GC_TIME) && RubyProf::GC_TIME
          @value_scale = 1000000
          @event_specification << 'gc_time'
        else
          raise "Unknown measure mode: #{RubyProf.measure_mode}"
      end
    end

    def print(options = {})
      validate_print_params(options)
      setup_options(options)
      determine_event_specification_and_value_scale
      print_threads
    end

    def validate_print_params(options)
      if options.is_a?(IO)
        raise ArgumentError, "#{self.class.name}#print cannot print to IO objects"
      elsif !options.is_a?(Hash)
        raise ArgumentError, "#{self.class.name}#print requires an options hash"
      end
    end

    def print_threads
      remove_subsidiary_files_from_previous_profile_runs
      @result.threads.each do |thread|
        print_thread(thread)
      end
    end

    def convert(value)
      (value * @value_scale).round
    end

    def file(method)
      method.source_file ? File.expand_path(method.source_file) : ''
    end

    def print_thread(thread)
      File.open(file_path_for_thread(thread), "w") do |f|
        print_headers(f, thread)
        thread.methods.reverse_each do |method|
          print_method(f, method)
        end
      end
    end

    def path
      @options[:path] || "."
    end

    def self.needs_dir?
      true
    end

    def remove_subsidiary_files_from_previous_profile_runs
      pattern = ["callgrind.out", $$, "*"].join(".")
      files = Dir.glob(File.join(path, pattern))
      FileUtils.rm_f(files)
    end

    def file_name_for_thread(thread)
      if thread.fiber_id == Fiber.current.object_id
        ["callgrind.out", $$].join(".")
      else
        ["callgrind.out", $$, thread.fiber_id].join(".")
      end
    end

    def file_path_for_thread(thread)
      File.join(path, file_name_for_thread(thread))
    end

    def print_headers(output, thread)
      output << "#{@event_specification}\n\n"
      # this doesn't work. kcachegrind does not fully support the spec.
      # output << "thread: #{thread.id}\n\n"
    end

    def print_method(output, method)
      # Print out the file and method name
      output << "fl=#{file(method)}\n"
      output << "fn=#{self.calltree_name(method)}\n"

      # Now print out the function line number and its self time
      output << "#{method.line} #{convert(method.self_time)}\n"

      # Now print out all the children methods
      method.call_trees.callees.each do |callee|
        output << "cfl=#{file(callee.target)}\n"
        output << "cfn=#{self.calltree_name(callee.target)}\n"
        output << "calls=#{callee.called} #{callee.line}\n"

        # Print out total times here!
        output << "#{callee.line} #{convert(callee.total_time)}\n"
      end
      output << "\n"
    end
  end
end
