# frozen_string_literal: true

require 'shellwords'

require_relative 'base_formatter'
require_relative 'mswin_helper' if RUBY_PLATFORM.include?('mswin')

module AmazingPrint
  module Formatters
    class FileFormatter < BaseFormatter
      attr_reader :file, :inspector, :options

      def initialize(file, inspector)
        super()
        @file = file
        @inspector = inspector
        @options = inspector.options
      end

      def format
        ls = info
        colorize(ls.empty? ? file.inspect : "#{file.inspect}\n#{ls.chop}", :file)
      end

      def info
        if RUBY_PLATFORM.include?('mswin')
          "#{GetChildItem.new(@file.path)}\n"
        else
          File.directory?(file) ? `ls -adlF #{file.path.shellescape}` : `ls -alF #{file.path.shellescape}`
        end
      end
    end
  end
end
