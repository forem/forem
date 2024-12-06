# frozen_string_literal: true

require 'shellwords'

require_relative 'base_formatter'
require_relative 'mswin_helper' if RUBY_PLATFORM.include?('mswin')

module AmazingPrint
  module Formatters
    class DirFormatter < BaseFormatter
      attr_reader :dir, :inspector, :options

      def initialize(dir, inspector)
        super()
        @dir = dir
        @inspector = inspector
        @options = inspector.options
      end

      def format
        ls = info
        colorize(ls.empty? ? dir.inspect : "#{dir.inspect}\n#{ls.chop}", :dir)
      end

      def info
        if RUBY_PLATFORM.include?('mswin')
          "#{GetChildItem.new(@dir.path)}\n"
        else
          `ls -alF #{dir.path.shellescape}`
        end
      end
    end
  end
end
