module Ransack
  module Nodes
    class Value < Node
      attr_accessor :value
      delegate :present?, :blank?, :to => :value

      def initialize(context, value = nil)
        super(context)
        @value = value
      end

      def persisted?
        false
      end

      def eql?(other)
        self.class == other.class && self.value == other.value
      end
      alias :== :eql?

      def hash
        value.hash
      end

      def cast(type)
        case type
        when :date
          cast_to_date(value)
        when :datetime, :timestamp, :time, :timestamptz
          cast_to_time(value)
        when :boolean
          cast_to_boolean(value)
        when :integer
          cast_to_integer(value)
        when :float
          cast_to_float(value)
        when :decimal
          cast_to_decimal(value)
        when :money
          cast_to_money(value)
        else
          cast_to_string(value)
        end
      end

      def cast_to_date(val)
        if val.respond_to?(:to_date)
          val.to_date rescue nil
        else
          y, m, d = *[val].flatten
          m ||= 1
          d ||= 1
          Date.new(y, m, d) rescue nil
        end
      end

      def cast_to_time(val)
        if val.is_a?(Array)
          Time.zone.local(*val) rescue nil
        else
          unless val.acts_like?(:time)
            val = val.is_a?(String) ? Time.zone.parse(val) : val.to_time rescue val
          end
          val.in_time_zone rescue nil
        end
      end

      def cast_to_boolean(val)
        if Constants::TRUE_VALUES.include?(val)
          true
        elsif Constants::FALSE_VALUES.include?(val)
          false
        else
          nil
        end
      end

      def cast_to_string(val)
        val.respond_to?(:to_s) ? val.to_s : String.new(val)
      end

      def cast_to_integer(val)
        val.blank? ? nil : val.to_i
      end

      def cast_to_float(val)
        val.blank? ? nil : val.to_f
      end

      def cast_to_decimal(val)
       if val.blank?
         nil
       elsif val.class == BigDecimal
         val
       elsif val.respond_to?(:to_d)
         val.to_d
       else
         val.to_s.to_d
       end
      end

      def cast_to_money(val)
        val.blank? ? nil : val.to_f.to_s
      end

      def inspect
        "Value <#{value}>"
      end

      def array_of_arrays?(val)
        Array === val && Array === val.first
      end
    end
  end
end
