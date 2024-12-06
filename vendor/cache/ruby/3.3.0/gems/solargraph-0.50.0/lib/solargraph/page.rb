# frozen_string_literal: true

require 'ostruct'
require 'tilt'
require 'yard'
require 'cgi'

module Solargraph
  class Page
    class Binder < OpenStruct
      # @param locals [Hash]
      # @param render_method [Proc]
      def initialize locals, render_method
        super(locals)
        define_singleton_method :render do |template, layout: false, locals: {}|
          render_method.call(template, layout: layout, locals: locals)
        end
        define_singleton_method :erb do |template, layout: false, locals: {}|
          render_method.call(template, layout: layout, locals: locals)
        end
      end

      # @param text [String]
      # @return [String]
      def htmlify text
        YARD::Templates::Helpers::Markup::RDocMarkup.new(text).to_html
      end

      # @param text [String]
      # @return [String]
      def escape text
        CGI.escapeHTML(text)
      end

      # @param code [String]
      # @return [String]
      def ruby_to_html code
        code
      end
    end
    private_constant :Binder

    # @param directory [String]
    def initialize directory = VIEWS_PATH
      directory = VIEWS_PATH if directory.nil? or !File.directory?(directory)
      directories = [directory]
      directories.push VIEWS_PATH if directory != VIEWS_PATH
      # @type [Proc]
      # @param template [String]
      # @param layout [Boolean]
      # @param locals [Hash]
      @render_method = proc { |template, layout: false, locals: {}|
        binder = Binder.new(locals, @render_method)
        if layout
          Tilt::ERBTemplate.new(Page.select_template(directories, 'layout')).render(binder) do
            Tilt::ERBTemplate.new(Page.select_template(directories, template)).render(binder)
          end
        else
          Tilt::ERBTemplate.new(Page.select_template(directories, template)).render(binder)
        end
      }
    end

    # @param template [String]
    # @param layout [Boolean]
    # @param locals [Hash]
    # @return [String]
    def render template, layout: true, locals: {}
      @render_method.call(template, layout: layout, locals: locals)
    end

    # @param directories [Array<String>]
    # @param name [String]
    # @return [String]
    def self.select_template directories, name
      directories.each do |dir|
        path = File.join(dir, "#{name}.erb")
        return path if File.file?(path)
      end
      raise FileNotFoundError, "Template not found: #{name}"
    end
  end
end
