# encoding: utf-8

require 'erb'
require 'fileutils'
require 'base64'
require 'set'
require 'stringio'

module RubyProf
  # Prints a HTML visualization of the call tree.
  #
  # To use the printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::CallStackPrinter.new(result)
  #   printer.print(STDOUT)

  class CallStackPrinter < AbstractPrinter
    include ERB::Util

    # Specify print options.
    #
    # options - Hash table
    #   :min_percent - Number 0 to 100 that specifes the minimum
    #                  %self (the methods self time divided by the
    #                  overall total time) that a method must take
    #                  for it to be printed out in the report.
    #                  Default value is 0.
    #
    #   :threshold   - a float from 0 to 100 that sets the threshold of
    #                  results displayed.
    #                  Default value is 1.0
    #
    #   :title       - a String to overide the default "ruby-prof call tree"
    #                  title of the report.
    #
    #   :expansion   - a float from 0 to 100 that sets the threshold of
    #                  results that are expanded, if the percent_total
    #                  exceeds it.
    #                  Default value is 10.0
    #
    #   :application - a String to overide the name of the application,
    #                  as it appears on the report.
    def print(output = STDOUT, options = {})
      setup_options(options)
      output << @erb.result(binding)
    end

    # :enddoc:
    def setup_options(options)
      super(options)
      @erb = ERB.new(self.template)
    end

    def print_stack(output, visited, call_tree, parent_time)
      total_time = call_tree.total_time
      percent_parent = (total_time/parent_time)*100
      percent_total = (total_time/@overall_time)*100
      return unless percent_total > min_percent
      color = self.color(percent_total)
      visible = percent_total >= threshold
      expanded = percent_total >= expansion
      display = visible ? "block" : "none"

      output << "<li class=\"color#{color}\" style=\"display:#{display}\">" << "\n"

      if visited.include?(call_tree)
        output << "<a href=\"#\" class=\"toggle empty\" ></a>" << "\n"
        output << "<span>%s %s</span>" % [link(call_tree.target, true), graph_link(call_tree)] << "\n"
      else
        visited << call_tree

        if call_tree.children.empty?
          output << "<a href=\"#\" class=\"toggle empty\" ></a>" << "\n"
        else
          visible_children = call_tree.children.any?{|ci| (ci.total_time/@overall_time)*100 >= threshold}
          image = visible_children ? (expanded ? "minus" : "plus") : "empty"
          output << "<a href=\"#\" class=\"toggle #{image}\" ></a>" << "\n"
        end
        output << "<span>%4.2f%% (%4.2f%%) %s %s</span>" % [percent_total, percent_parent,
                                                            link(call_tree.target, false), graph_link(call_tree)] << "\n"

        unless call_tree.children.empty?
          output <<  (expanded ? '<ul>' : '<ul style="display:none">')  << "\n"
          call_tree.children.sort_by{|c| -c.total_time}.each do |child_call_tree|
            print_stack(output, visited, child_call_tree, total_time)
          end
          output << '</ul>' << "\n"
        end

        visited.delete(call_tree)
      end
      output << '</li>' << "\n"
    end

    def name(call_tree)
      method = call_tree.target
      method.full_name
    end

    def link(method, recursive)
      method_name = "#{recursive ? '*' : ''}#{method.full_name}"
      if method.source_file.nil?
        h method_name
      else
        file = File.expand_path(method.source_file)
       "<a href=\"file://#{file}##{method.line}\">#{h method_name}</a>"
      end
    end

    def graph_link(call_tree)
      total_calls = call_tree.target.called
      totals = total_calls.to_s
      "[#{call_tree.called} calls, #{totals} total]"
    end

    def method_href(method)
      h(method.full_name.gsub(/[><#\.\?=:]/,"_"))
    end

    def total_time(call_trees)
      sum(call_trees.map{|ci| ci.total_time})
    end

    def sum(a)
      a.inject(0.0){|s,t| s+=t}
    end

    def dump(ci)
      $stderr.printf "%s/%d t:%f s:%f w:%f  \n", ci, ci.object_id, ci.total_time, ci.self_time, ci.wait_time
    end

    def color(p)
      case i = p.to_i
      when 0..5
        "01"
      when 5..10
        "05"
      when 100
        "9"
      else
        "#{i/10}"
      end
    end

    def application
      @options[:application] || $PROGRAM_NAME
    end

    def arguments
      ARGV.join(' ')
    end

    def title
      @title ||= @options.delete(:title) || "ruby-prof call tree"
    end

    def threshold
      @options[:threshold] || 1.0
    end

    def expansion
      @options[:expansion] || 10.0
    end

    def base64_image
      @data ||= begin
        file = open_asset('call_stack_printer.png')
        Base64.encode64(file).gsub(/\n/, '')
      end
    end

    def template
      open_asset('call_stack_printer.html.erb')
    end
  end
end
