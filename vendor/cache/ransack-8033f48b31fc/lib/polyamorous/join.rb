module Polyamorous
  class Join
    include TreeNode

    attr_accessor :name
    attr_reader :type, :klass

    def initialize(name, type = InnerJoin, klass = nil)
      @name = name
      @type = convert_to_arel_join_type(type)
      @klass = convert_to_class(klass) if klass
    end

    def klass=(klass)
      @klass = convert_to_class(klass) if klass
    end

    def type=(type)
      @type = convert_to_arel_join_type(type) if type
    end

    def hash
      [@name, @type, @klass].hash
    end

    def eql?(other)
      self.class == other.class &&
      self.name  == other.name &&
      self.type  == other.type &&
      self.klass == other.klass
    end

    alias :== :eql?

    def add_to_tree(hash)
      hash[self] ||= {}
    end

    private

    def convert_to_arel_join_type(type)
      case type
      when 'inner', :inner
        InnerJoin
      when 'outer', :outer
        OuterJoin
      when Class
        if [InnerJoin, OuterJoin].include? type
          type
        else
          raise ArgumentError, "#{type} cannot be converted to an ARel join type"
        end
      else
        raise ArgumentError, "#{type} cannot be converted to an ARel join type"
      end
    end

    def convert_to_class(value)
      case value
      when String, Symbol
        Kernel.const_get(value)
      when Class
        value
      else
        raise ArgumentError, "#{value} cannot be converted to a Class"
      end
    end

  end
end
