# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------

# rubocop:disable Metrics/ClassLength, Metrics/MethodLength

require_relative 'indentator'
require_relative 'ext_loader'

module AmazingPrint
  class Inspector
    attr_accessor :options, :indentator

    AP = :__amazing_print__

    ##
    # Unload the cached dotfile and load it again.
    #
    def self.reload_dotfile
      @@dotfile = nil
      new.send :load_dotfile
      true
    end

    def initialize(options = {})
      @options = {
        indent: 4, # Number of spaces for indenting.
        index: true, # Display array indices.
        html: false, # Use ANSI color codes rather than HTML.
        multiline: true, # Display in multiple lines.
        plain: false, # Use colors.
        raw: false, # Do not recursively format instance variables.
        sort_keys: false,  # Do not sort hash keys.
        sort_vars: true,   # Sort instance variables.
        limit: false, # Limit arrays & hashes. Accepts bool or int.
        ruby19_syntax: false, # Use Ruby 1.9 hash syntax in output.
        class_name: :class, # Method used to get Instance class name.
        object_id: true, # Show object_id.
        color: {
          args: :whiteish,
          array: :white,
          bigdecimal: :blue,
          class: :yellow,
          date: :greenish,
          falseclass: :red,
          fixnum: :blue,
          integer: :blue,
          float: :blue,
          hash: :whiteish,
          keyword: :cyan,
          method: :purpleish,
          nilclass: :red,
          rational: :blue,
          string: :yellowish,
          struct: :whiteish,
          symbol: :cyanish,
          time: :greenish,
          trueclass: :green,
          variable: :cyanish
        }
      }

      # Merge custom defaults and let explicit options parameter override them.
      merge_custom_defaults!
      merge_options!(options)

      @formatter = AmazingPrint::Formatter.new(self)
      @indentator = AmazingPrint::Indentator.new(@options[:indent].abs)
      Thread.current[AP] ||= []

      ExtLoader.call
    end

    def current_indentation
      indentator.indentation
    end

    def increase_indentation(&blk)
      indentator.indent(&blk)
    end

    # Dispatcher that detects data nesting and invokes object-aware formatter.
    #---------------------------------------------------------------------------
    def awesome(object)
      if Thread.current[AP].include?(object.object_id)
        nested(object)
      else
        begin
          Thread.current[AP] << object.object_id
          unnested(object)
        ensure
          Thread.current[AP].pop
        end
      end
    end

    # Return true if we are to colorize the output.
    #---------------------------------------------------------------------------
    def colorize?
      AmazingPrint.force_colors ||= false
      AmazingPrint.force_colors || (
        if defined? @colorize_stdout
          @colorize_stdout
        else
          @colorize_stdout = $stdout.tty? && (
            (
              ENV['TERM'] &&
              ENV['TERM'] != 'dumb'
            ) ||
            ENV['ANSICON']
          )
        end
      )
    end

    private

    # Format nested data, for example:
    #   arr = [1, 2]; arr << arr
    #   => [1,2, [...]]
    #   hash = { :a => 1 }; hash[:b] = hash
    #   => { :a => 1, :b => {...} }
    #---------------------------------------------------------------------------
    def nested(object)
      case printable(object)
      when :array  then @formatter.colorize('[...]', :array)
      when :hash   then @formatter.colorize('{...}', :hash)
      when :struct then @formatter.colorize('{...}', :struct)
      else @formatter.colorize("...#{object.class}...", :class)
      end
    end

    #---------------------------------------------------------------------------
    def unnested(object)
      @formatter.format(object, printable(object))
    end

    # Turn class name into symbol, ex: Hello::World => :hello_world. Classes
    # that inherit from Array, Hash, File, Dir, and Struct are treated as the
    # base class.
    #---------------------------------------------------------------------------
    def printable(object)
      case object
      when Array  then :array
      when Hash   then :hash
      when File   then :file
      when Dir    then :dir
      when Struct then :struct
      else object.class.to_s.gsub(/:+/, '_').downcase.to_sym
      end
    end

    # Update @options by first merging the :color hash and then the remaining
    # keys.
    #---------------------------------------------------------------------------
    def merge_options!(options = {})
      @options[:color].merge!(options.delete(:color) || {})
      @options.merge!(options)
    end

    def find_dotfile
      xdg_config_home = File.expand_path(ENV.fetch('XDG_CONFIG_HOME', '~/.config'))
      xdg_config_path = File.join(xdg_config_home, 'aprc') # ${XDG_CONFIG_HOME}/aprc

      return xdg_config_path if File.exist?(xdg_config_path)

      # default to ~/.aprc
      File.join(Dir.home, '.aprc')
    end

    # This method needs to be mocked during testing so that it always loads
    # predictable values
    #---------------------------------------------------------------------------
    def load_dotfile
      return if @@dotfile # Load the dotfile only once.

      dotfile = find_dotfile
      load dotfile if dotfile_readable?(dotfile)
    end

    def dotfile_readable?(dotfile)
      @@dotfile_readable = File.readable?(@@dotfile = dotfile) if @@dotfile_readable.nil? || @@dotfile != dotfile
      @@dotfile_readable
    end
    @@dotfile_readable = @@dotfile = nil

    # Load ~/.aprc file with custom defaults that override default options.
    #---------------------------------------------------------------------------
    def merge_custom_defaults!
      load_dotfile
      merge_options!(AmazingPrint.defaults) if AmazingPrint.defaults.is_a?(Hash)
    rescue StandardError => e
      warn "Could not load '.aprc' from ENV['HOME']: #{e}"
    end
  end
end

# rubocop:enable Metrics/ClassLength, Metrics/MethodLength
