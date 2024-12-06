module Naught
  if defined? ::BasicObject
    class BasicObject < ::BasicObject
    end
  else
    class BasicObject #:nodoc:
      keep = %w(
        ! != == __id__ __send__ equal? instance_eval instance_exec
        method_missing singleton_method_added singleton_method_removed
        singleton_method_undefined
      )
      instance_methods.each do |method_name|
        undef_method(method_name) unless keep.include?(method_name)
      end
    end
  end
end
