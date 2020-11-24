module Ransack
  module Nodes
    class Grouping < Node
      attr_reader :conditions
      attr_accessor :combinator
      alias :m :combinator
      alias :m= :combinator=

      i18n_word :condition, :and, :or
      i18n_alias :c => :condition, :n => :and, :o => :or

      delegate :each, :to => :values

      def initialize(context, combinator = nil)
        super(context)
        self.combinator = combinator.to_s if combinator
      end

      def persisted?
        false
      end

      def translate(key, options = {})
        super or Translate.attribute(
          key.to_s, options.merge(:context => context)
        )
      end

      def conditions
        @conditions ||= []
      end
      alias :c :conditions

      def conditions=(conditions)
        case conditions
        when Array
          conditions.each do |attrs|
            condition = Condition.new(@context).build(attrs)
            self.conditions << condition if condition.valid?
          end
        when Hash
          conditions.each do |index, attrs|
            condition = Condition.new(@context).build(attrs)
            self.conditions << condition if condition.valid?
          end
        end
        remove_duplicate_conditions!
      end
      alias :c= :conditions=

      def [](key)
        conditions.detect { |c| c.key == key.to_s }
      end

      def []=(key, value)
        conditions.reject! { |c| c.key == key.to_s }
        self.conditions << value
      end

      def values
        conditions + groupings
      end

      def respond_to?(method_id)
        super or begin
          method_name = method_id.to_s
          attribute_method?(method_name) ? true : false
        end
      end

      def build_condition(opts = {})
        new_condition(opts).tap do |condition|
          self.conditions << condition
        end
      end

      def new_condition(opts = {})
        attrs = opts[:attributes] || 1
        vals = opts[:values] || 1
        condition = Condition.new(@context)
        attrs.times { condition.build_attribute }
        vals.times { condition.build_value }
        condition
      end

      def groupings
        @groupings ||= []
      end
      alias :g :groupings

      def groupings=(groupings)
        case groupings
        when Array
          groupings.each do |attrs|
            grouping_object = new_grouping(attrs)
            self.groupings << grouping_object if grouping_object.values.any?
          end
        when Hash
          groupings.each do |index, attrs|
            grouping_object = new_grouping(attrs)
            self.groupings << grouping_object if grouping_object.values.any?
          end
        else
          raise ArgumentError,
            "Invalid argument (#{groupings.class}) supplied to groupings="
        end
      end
      alias :g= :groupings=

      def method_missing(method_id, *args)
        method_name = method_id.to_s
        writer = method_name.sub!(/\=$/, ''.freeze)
        if attribute_method?(method_name)
          if writer
            write_attribute(method_name, *args)
          else
            read_attribute(method_name)
          end
        else
          super
        end
      end

      def attribute_method?(name)
        stripped_name = strip_predicate_and_index(name)
        return true if @context.attribute_method?(stripped_name) ||
                       @context.attribute_method?(name)
        case stripped_name
        when /^(g|c|m|groupings|conditions|combinator)=?$/
          true
        else
          stripped_name
          .split(/_and_|_or_/)
          .none? { |n| !@context.attribute_method?(n) }
        end
      end

      def build_grouping(params = {})
        params ||= {}
        new_grouping(params).tap do |new_grouping|
          self.groupings << new_grouping
        end
      end

      def new_grouping(params = {})
        Grouping.new(@context).build(params)
      end

      def build(params)
        params.with_indifferent_access.each do |key, value|
          case key
          when /^(g|c|m)$/
            self.send("#{key}=", value)
          else
            write_attribute(key.to_s, value)
          end
        end
        self
      end

      def inspect
        data = [
          ['conditions'.freeze, conditions], [Constants::COMBINATOR, combinator]
        ]
        .reject { |e| e[1].blank? }
        .map { |v| "#{v[0]}: #{v[1]}" }
        .join(', '.freeze)
        "Grouping <#{data}>"
      end

      private

      def write_attribute(name, val)
        # TODO: Methods
        if condition = Condition.extract(@context, name, val)
          self[name] = condition
        end
      end

      def read_attribute(name)
        if self[name].respond_to?(:value)
          self[name].value
        else
          self[name]
        end
      end

      def strip_predicate_and_index(str)
        string = str[/(.+?)\(/, 1] || str.dup
        Predicate.detect_and_strip_from_string!(string)
        string
      end

      def remove_duplicate_conditions!
        # If self.conditions.uniq! is called without passing a block, then
        # conditions differing only by ransacker_args within attributes are
        # wrongly considered equal and are removed.
        self.conditions.uniq! do |c|
          c.attributes.map { |a| [a.name, a.ransacker_args] }.flatten +
          [c.predicate.name] +
          c.values.map { |v| v.value }
        end
      end
    end
  end
end
