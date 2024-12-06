#!/usr/bin/env ruby

require "rake"
require "rake/tasklib"

require "guard/cli"

module Guard
  # Provides a method to define a Rake task that
  # runs the Guard plugins.
  #
  class RakeTask < ::Rake::TaskLib
    # Name of the main, top level task
    attr_accessor :name

    # CLI options
    attr_accessor :options

    # Initialize the Rake task
    #
    # @param [Symbol] name the name of the Rake task
    # @param [String] options the CLI options
    # @yield [Guard::RakeTask] the task
    #
    def initialize(name = :guard, options = "")
      @name = name
      @options = options

      yield self if block_given?

      desc "Starts Guard with options: '#{options}'"
      task name => ["#{name}:start"]

      namespace(name) do
        desc "Starts Guard with options: '#{options}'"
        task(:start) do
          ::Guard::CLI.start(options.split)
        end
      end
    end
  end
end
