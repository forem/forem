class Fastly
  # Collection of frequently used utility methods
  module Util
    def self.class_to_path(klass, append_s = false)
      klass_string = klass.to_s.split('::')[-1]
      klass_string = klass_string.gsub(/([^A-Z])([A-Z]+)/, '\1_\2').downcase
      append_s ? "#{klass_string}s" : klass_string
    end
  end
end
