module Rpush
  module Deprecatable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def deprecated(method_name, version, msg = nil)
        method_name_as_var = method_name.to_s.tr('=', '_setter_')
        instance_eval do
          alias_method "#{method_name_as_var}_without_warning", method_name
        end
        warning = "#{method_name} is deprecated and will be removed from Rpush #{version}."
        warning << " #{msg}" if msg
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{method_name}(*args, &blk)
            Rpush::Deprecation.warn_with_backtrace(#{warning.inspect})
            #{method_name_as_var}_without_warning(*args, &blk)
          end
        RUBY
      end
    end
  end
end
