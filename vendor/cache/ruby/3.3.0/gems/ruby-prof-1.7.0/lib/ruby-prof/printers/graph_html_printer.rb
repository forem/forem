# encoding: utf-8

require 'erb'

module RubyProf
  # Generates graph[link:files/examples/graph_html.html] profile reports as html.
  # To use the graph html printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::GraphHtmlPrinter.new(result)
  #   printer.print(STDOUT, :min_percent=>0)
  #
  # The Graph printer takes the following options in its print methods:

  class GraphHtmlPrinter < AbstractPrinter
    include ERB::Util

    def setup_options(options)
      super(options)
      @erb = ERB.new(self.template)
    end

    def print(output = STDOUT, options = {})
      setup_options(options)
      output << @erb.result(binding)
    end

    # Creates a link to a method.  Note that we do not create
    # links to methods which are under the min_percent
    # specified by the user, since they will not be
    # printed out.
    def create_link(thread, overall_time, method)
      total_percent = (method.total_time/overall_time) * 100
      if total_percent < min_percent
        # Just return name
        h method.full_name
      else
        href = '#' + method_href(thread, method)
        "<a href=\"#{href}\">#{h method.full_name}</a>"
      end
    end

    def method_href(thread, method)
      h(method.full_name.gsub(/[><#\.\?=:]/,"_") + "_" + thread.fiber_id.to_s)
    end

    def file_link(path, linenum)
      if path.nil?
        ""
      else
        srcfile = File.expand_path(path)
        "<a href=\"file://#{h srcfile}##{linenum}\" title=\"#{h srcfile}:#{linenum}\">#{linenum}</a>"
      end
    end

    def template
      open_asset('graph_printer.html.erb')
    end
  end
end
