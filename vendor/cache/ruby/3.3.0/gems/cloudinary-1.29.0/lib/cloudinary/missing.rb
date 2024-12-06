unless nil.respond_to?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end

    # An object is present if it's not blank.
    #
    # @return [true, false]
    def present?
      !blank?
    end unless Object.instance_methods.include? :present?

    def presence
      self if present?
    end  unless Object.instance_methods.include? :presence
  end

  class NilClass #:nodoc:
    def blank?
      true
    end
  end
  
  class FalseClass #:nodoc:
    def blank?
      true
    end
  end
  
  class TrueClass #:nodoc:
    def blank?
      false
    end
  end
  
  class Array #:nodoc:
    alias_method :blank?, :empty?
  end
  
  class Hash #:nodoc:
    alias_method :blank?, :empty?
  end
  
  class String #:nodoc:
    def blank?
      self !~ /\S/
    end
  end
  
  class Numeric #:nodoc:
    def blank?
      false
    end
  end  
end
