# frozen_string_literal: true

module MemoryProfiler
  class Helpers

    def initialize
      @gem_guess_cache = Hash.new
      @location_cache = Hash.new { |h, k| h[k] = Hash.new.compare_by_identity }
      @class_name_cache = Hash.new.compare_by_identity
      @string_cache = Hash.new
    end

    def guess_gem(path)
      @gem_guess_cache[path] ||=
        if /(\/gems\/.*)*\/gems\/(?<gemname>[^\/]+)/ =~ path
          gemname
        elsif /\/rubygems[\.\/]/ =~ path
          "rubygems"
        elsif /ruby\/\d\.[^\/]+\/(?<stdlib>[^\/\.]+)/ =~ path
          stdlib
        elsif /(?<app>[^\/]+\/(bin|app|lib))/ =~ path
          app
        else
          "other"
        end
    end

    def lookup_location(file, line)
      @location_cache[file][line] ||= "#{file}:#{line}"
    end

    KERNEL_CLASS_METHOD = Kernel.instance_method(:class)
    if UnboundMethod.method_defined?(:bind_call)
      def object_class(obj)
        klass = obj.class rescue nil
        unless Class === klass
          # attempt to determine the true Class when .class returns something other than a Class
          klass = KERNEL_CLASS_METHOD.bind_call(obj)
        end
        klass
      end
    else
      def object_class(obj)
        klass = obj.class rescue nil
        unless Class === klass
          # attempt to determine the true Class when .class returns something other than a Class
          klass = KERNEL_CLASS_METHOD.bind(obj).call
        end
        klass
      end
    end

    if Object.name.frozen? # Since Ruby 2.7 Module#name no longer allocate a new string
      def lookup_class_name(klass)
        ((klass.is_a?(Class) && klass.name) || '<<Unknown>>').to_s
      end
    else
      def lookup_class_name(klass)
        @class_name_cache[klass] ||= ((klass.is_a?(Class) && klass.name) || '<<Unknown>>').to_s
      end
    end

    def lookup_string(obj)
      # This string is shortened to 200 characters which is what the string report shows
      # The string report can still list unique strings longer than 200 characters
      #   separately because the object_id of the shortened string will be different
      @string_cache[obj] ||= String.new << obj[0, 200]
    end
  end
end
