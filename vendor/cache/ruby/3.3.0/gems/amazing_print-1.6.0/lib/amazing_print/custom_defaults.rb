# frozen_string_literal: true

module AmazingPrint
  class << self
    attr_accessor :defaults, :force_colors

    # Class accessor to force colorized output (ex. forked subprocess where TERM
    # might be dumb).
    #---------------------------------------------------------------------------
    def force_colors!(colors: true)
      @force_colors = colors
    end

    def console?
      boolean(defined?(IRB) || defined?(Pry))
    end

    def rails_console?
      console? && boolean(defined?(Rails::Console) || ENV['RAILS_ENV'])
    end

    def diet_rb
      IRB.formatter = Class.new(IRB::Formatter) do
        def inspect_object(object)
          object.ai
        end
      end.new
    end

    def usual_rb
      IRB::Irb.class_eval do
        def output_value(_omit = false) # rubocop:disable Style/OptionalBooleanParameter
          ap @context.last_value
        rescue NoMethodError
          puts "(Object doesn't support #ai)"
        end
      end
    end

    def irb!
      return unless defined?(IRB)

      IRB.version.include?('DietRB') ? diet_rb : usual_rb
    end

    def pry!
      return unless defined?(Pry)

      Pry.print = proc do |_output, value, pry_instance|
        pry_instance.pager.open do |pager|
          pager.print "#{value.ai}\n"
        end
      end
    end

    ##
    # Reload the cached custom configurations.
    #
    def reload!
      AmazingPrint::Inspector.reload_dotfile
    end

    private

    # Takes a value and returns true unless it is false or nil
    # This is an alternative to the less readable !!(value)
    # https://github.com/bbatsov/ruby-style-guide#no-bang-bang
    def boolean(value)
      value ? true : false
    end
  end
end
