# frozen_string_literal: true

module MemoryProfiler
  class Results
    UNIT_PREFIXES = {
      0 => 'B',
      3 => 'kB',
      6 => 'MB',
      9 => 'GB',
      12 => 'TB',
      15 => 'PB',
      18 => 'EB',
      21 => 'ZB',
      24 => 'YB'
    }.freeze

    TYPES   = ["allocated", "retained"].freeze
    METRICS = ["memory", "objects"].freeze
    NAMES   = ["gem", "file", "location", "class"].freeze

    def self.register_type(name, stat_attribute)
      @@lookups ||= []
      @@lookups << [name, stat_attribute]

      TYPES.each do |type|
        METRICS.each do |metric|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{type}_#{metric}_by_#{name}                                                  # def allocated_memory_by_file
              @#{type}_#{metric}_by ||= {}                                                    #   @allocated_memory_by ||= {}
                                                                                              #
              @#{type}_#{metric}_by['#{name}'] ||= begin                                      #   @allocated_memory_by['file'] ||= begin
                _, stat_attribute = @@lookups.find { |(n, _stat_attribute)| n == '#{name}' }  #     _, stat_attribute = @@lookups.find { |(n, _stat_attribute)| n == 'file' }
                @#{type}.top_n_#{metric}(@top, stat_attribute)                                #     @allocated.top_n_memory(@top, stat_attribute)
              end                                                                             #   end
            end                                                                               # end
          RUBY
        end
      end
    end

    register_type 'gem', :gem
    register_type 'file', :file
    register_type 'location', :location
    register_type 'class', :class_name

    attr_writer :strings_retained, :strings_allocated
    attr_accessor :total_retained, :total_allocated
    attr_accessor :total_retained_memsize, :total_allocated_memsize

    def initialize
      @allocated = StatHash.new
      @retained = StatHash.new
      @top = 50
    end

    def register_results(allocated, retained, top)
      @allocated = allocated
      @retained = retained
      @top = top

      self.total_allocated = allocated.size
      self.total_allocated_memsize = total_memsize(allocated)
      self.total_retained = retained.size
      self.total_retained_memsize = total_memsize(retained)

      self
    end

    def strings_allocated
      @strings_allocated ||= string_report(@allocated, @top)
    end

    def strings_retained
      @strings_retained ||= string_report(@retained, @top)
    end

    def scale_bytes(bytes)
      return "0 B" if bytes.zero?

      scale = Math.log10(bytes).div(3) * 3
      scale = 24 if scale > 24
      "%.2f #{UNIT_PREFIXES[scale]}" % (bytes / 10.0**scale)
    end

    def string_report(data, top)
      grouped_strings = Hash.new { |hash, key| hash[key] = [] }
      data.each_value do |stat|
        if stat.string_value
          grouped_strings[stat.string_value.object_id] << stat
        end
      end

      grouped_strings = grouped_strings.values

      if grouped_strings.size > top
        grouped_strings.sort_by!(&:size)
        grouped_strings = grouped_strings.drop(grouped_strings.size - top)
      end

      grouped_strings
        .sort! { |a, b| a.size == b.size ? a[0].string_value <=> b[0].string_value : b.size <=> a.size }
        .map! do |list|
          # Return array of [string, [[location, count], [location, count], ...]
          [
            list[0].string_value,
            list.group_by { |stat| stat.location }
              .map { |location, stat_list| [location, stat_list.size] }
              .sort_by!(&:last)
              .reverse!
          ]
        end
    end

    # Output the results of the report
    # @param [Hash] options the options for output
    # @option opts [String] :to_file a path to your log file
    # @option opts [Boolean] :color_output a flag for whether to colorize output
    # @option opts [Integer] :retained_strings how many retained strings to print
    # @option opts [Integer] :allocated_strings how many allocated strings to print
    # @option opts [Boolean] :detailed_report should report include detailed information
    # @option opts [Boolean] :scale_bytes calculates unit prefixes for the numbers of bytes
    # @option opts [Boolean] :normalize_paths print location paths relative to gem's source directory.
    def pretty_print(io = $stdout, **options)
      # Handle the special case that Ruby PrettyPrint expects `pretty_print`
      # to be a customized pretty printing function for a class
      return io.pp_object(self) if defined?(PP) && io.is_a?(PP)

      io = File.open(options[:to_file], "w") if options[:to_file]

      color_output = options.fetch(:color_output) { io.respond_to?(:isatty) && io.isatty }
      @colorize = color_output ? Polychrome.new : Monochrome.new

      if options[:scale_bytes]
        total_allocated_output = scale_bytes(total_allocated_memsize)
        total_retained_output  = scale_bytes(total_retained_memsize)
      else
        total_allocated_output = "#{total_allocated_memsize} bytes"
        total_retained_output  = "#{total_retained_memsize} bytes"
      end

      io.puts "Total allocated: #{total_allocated_output} (#{total_allocated} objects)"
      io.puts "Total retained:  #{total_retained_output} (#{total_retained} objects)"

      unless options[:detailed_report] == false
        TYPES.each do |type|
          METRICS.each do |metric|
            NAMES.each do |name|
              dump_data(io, type, metric, name, options)
            end
          end
        end

        io.puts
        print_string_reports(io, options)
      end

      io.close if io.is_a? File
    end

    def print_string_reports(io, options)
      TYPES.each do |type|
        dump_opts = {
          normalize_paths: options[:normalize_paths],
          limit: options["#{type}_strings".to_sym]
        }
        dump_strings(io, type, dump_opts)
      end
    end

    def normalize_path(path)
      @normalize_path ||= {}
      @normalize_path[path] ||= begin
        if %r!(/gems/.*)*/gems/(?<gemname>[^/]+)(?<rest>.*)! =~ path
          "#{gemname}#{rest}"
        elsif %r!ruby/\d\.[^/]+/(?<stdlib>[^/.]+)(?<rest>.*)! =~ path
          "ruby/lib/#{stdlib}#{rest}"
        elsif %r!(?<app>[^/]+/(bin|app|lib))(?<rest>.*)! =~ path
          "#{app}#{rest}"
        else
          path
        end
      end
    end

    private

    def total_memsize(stat_hash)
      sum = 0
      stat_hash.each_value do |stat|
        sum += stat.memsize
      end
      sum
    end

    def print_title(io, title)
      io.puts
      io.puts title
      io.puts @colorize.line("-----------------------------------")
    end

    def print_output(io, topic, detail)
      io.puts "#{@colorize.path(topic.to_s.rjust(10))}  #{detail}"
    end

    def dump_data(io, type, metric, name, options)
      print_title  io, "#{type} #{metric} by #{name}"
      data = self.send "#{type}_#{metric}_by_#{name}"

      scale_data = metric == "memory" && options[:scale_bytes]
      normalize_paths = options[:normalize_paths]

      if data && !data.empty?
        data.each do |item|
          count = scale_data ? scale_bytes(item[:count]) : item[:count]
          value = normalize_paths ? normalize_path(item[:data]) : item[:data]
          print_output io, count, value
        end
      else
        io.puts "NO DATA"
      end

      nil
    end

    def dump_strings(io, type, options)
      strings = self.send("strings_#{type}") || []
      return if strings.empty?

      options = {} unless options.is_a?(Hash)

      if (limit = options[:limit])
        return if limit == 0
        strings = strings[0...limit]
      end

      normalize_paths = options[:normalize_paths]

      print_title(io, "#{type.capitalize} String Report")
      strings.each do |string, stats|
        print_output io, (stats.reduce(0) { |a, b| a + b[1] }), @colorize.string(string.inspect)
        stats.sort_by { |x, y| [-y, x] }.each do |location, count|
          location = normalize_path(location) if normalize_paths
          print_output io, count, location
        end
        io.puts
      end

      nil
    end

  end

end
