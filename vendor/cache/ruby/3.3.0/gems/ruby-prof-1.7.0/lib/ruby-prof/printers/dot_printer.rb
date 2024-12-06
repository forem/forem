# encoding: utf-8

require 'set'

module RubyProf
  # Generates a graphviz graph in dot format.
  #
  # To use the dot printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::DotPrinter.new(result)
  #   printer.print(STDOUT)
  #
  # You can use either dot viewer such as GraphViz, or the dot command line tool
  # to reformat the output into a wide variety of outputs:
  #
  #   dot -Tpng graph.dot > graph.png
  #
  class DotPrinter < RubyProf::AbstractPrinter
    CLASS_COLOR = '"#666666"'
    EDGE_COLOR  = '"#666666"'

    # Creates the DotPrinter using a RubyProf::Proile.
    def initialize(result)
      super(result)
      @seen_methods = Set.new
    end

    # Print a graph report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file. The default value is
    # STDOUT.
    #
    # options - Hash of print options.  See #setup_options
    # for more information.
    #
    # When profiling results that cover a large number of method calls it
    # helps to use the :min_percent option, for example:
    #
    #   DotPrinter.new(result).print(STDOUT, :min_percent=>5)
    #
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)

      puts 'digraph "Profile" {'
      #puts "label=\"#{mode_name} >=#{min_percent}%\\nTotal: #{total_time}\";"
      puts "labelloc=t;"
      puts "labeljust=l;"
      print_threads
      puts '}'
    end

    private

    # Something of a hack, figure out which constant went with the
    # RubyProf.measure_mode so that we can display it.  Otherwise it's easy to
    # forget what measurement was made.
    def mode_name
      RubyProf.constants.find{|c| RubyProf.const_get(c) == RubyProf.measure_mode}
    end

    def print_threads
      @result.threads.each do |thread|
        puts "subgraph \"Thread #{thread.id}\" {"

        print_thread(thread)
        puts "}"

        print_classes(thread)
      end
    end

    # Determines an ID to use to represent the subject in the Dot file.
    def dot_id(subject)
      subject.object_id
    end

    def print_thread(thread)
      total_time = thread.total_time
      thread.methods.sort_by(&sort_method).reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100

        next if total_percentage < min_percent
        name = method.full_name.split("#").last
        puts "#{dot_id(method)} [label=\"#{name}\\n(#{total_percentage.round}%)\"];"
        @seen_methods << method
        print_edges(total_time, method)
      end
    end

    def print_classes(thread)
      grouped = {}
      thread.methods.each{|m| grouped[m.klass_name] ||= []; grouped[m.klass_name] << m}
      grouped.each do |cls, methods2|
        # Filter down to just seen methods
        big_methods = methods2.select{|m| @seen_methods.include? m}

        if !big_methods.empty?
          puts "subgraph cluster_#{cls.object_id} {"
          puts "label = \"#{cls}\";"
          puts "fontcolor = #{CLASS_COLOR};"
          puts "fontsize = 16;"
          puts "color = #{CLASS_COLOR};"
          big_methods.each do |m|
            puts "#{m.object_id};"
          end
          puts "}"
        end
      end
    end

    def print_edges(total_time, method)
      method.call_trees.callers.sort_by(&:total_time).reverse.each do |call_tree|
        target_percentage = (call_tree.target.total_time / total_time) * 100.0
        next if target_percentage < min_percent

        # Get children method
        puts "#{dot_id(method)} -> #{dot_id(call_tree.target)} [label=\"#{call_tree.called}/#{call_tree.target.called}\" fontsize=10 fontcolor=#{EDGE_COLOR}];"
      end
    end

    # Silly little helper for printing to the @output
    def puts(str)
      @output.puts(str)
    end

  end
end
