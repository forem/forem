module Ransack
  module Nodes
    class Condition < Node
      i18n_word :attribute, :predicate, :combinator, :value
      i18n_alias :a => :attribute, :p => :predicate,
                 :m => :combinator, :v => :value

      attr_accessor :predicate

      class << self
        def extract(context, key, values)
          attributes, predicate, combinator =
            extract_values_for_condition(key, context)

          if attributes.size > 0 && predicate
            condition = self.new(context)
            condition.build(
              :a => attributes,
              :p => predicate.name,
              :m => combinator,
              :v => predicate.wants_array ? Array(values) : [values]
            )
            # TODO: Figure out what to do with multiple types of attributes,
            # if anything. Tempted to go with "garbage in, garbage out" here.
            if predicate.validate(condition.values, condition.default_type)
              condition
            else
              nil
            end
          end
        end

        private

          def extract_values_for_condition(key, context = nil)
            str = key.dup
            name = Predicate.detect_and_strip_from_string!(str)
            predicate = Predicate.named(name)

            unless predicate || Ransack.options[:ignore_unknown_conditions]
              raise ArgumentError, "No valid predicate for #{key}"
            end

            if context.present?
              str = context.ransackable_alias(str)
            end

            combinator =
            if str.match(/_(or|and)_/)
              $1
            else
              nil
            end

            if context.present? && context.attribute_method?(str)
              attributes = [str]
            else
              attributes = str.split(/_and_|_or_/)
            end

            [attributes, predicate, combinator]
          end
      end

      def valid?
        attributes.detect(&:valid?) && predicate && valid_arity? &&
          predicate.validate(values, default_type) && valid_combinator?
      end

      def valid_arity?
        values.size <= 1 || predicate.wants_array
      end

      def attributes
        @attributes ||= []
      end
      alias :a :attributes

      def attributes=(args)
        case args
        when Array
          args.each do |name|
            build_attribute(name)
          end
        when Hash
          args.each do |index, attrs|
            build_attribute(attrs[:name], attrs[:ransacker_args])
          end
        else
          raise ArgumentError,
            "Invalid argument (#{args.class}) supplied to attributes="
        end
      end
      alias :a= :attributes=

      def values
        @values ||= []
      end
      alias :v :values

      def values=(args)
        case args
        when Array
          args.each do |val|
            val = Value.new(@context, val)
            self.values << val
          end
        when Hash
          args.each do |index, attrs|
            val = Value.new(@context, attrs[:value])
            self.values << val
          end
        else
          raise ArgumentError,
            "Invalid argument (#{args.class}) supplied to values="
        end
      end
      alias :v= :values=

      def combinator
        @attributes.size > 1 ? @combinator : nil
      end

      def combinator=(val)
        @combinator = Constants::AND_OR.detect { |v| v == val.to_s } || nil
      end
      alias :m= :combinator=
      alias :m :combinator


      # == build_attribute
      #
      #  This method was originally called from Nodes::Grouping#new_condition
      #  only, without arguments, without #valid? checking, to build a new
      #  grouping condition.
      #
      #  After refactoring in 235eae3, it is now called from 2 places:
      #
      #  1. Nodes::Condition#attributes=, with +name+ argument passed or +name+
      #     and +ransacker_args+. Attributes are included only if #valid?.
      #
      #  2. Nodes::Grouping#new_condition without arguments. In this case, the
      #     #valid? conditional needs to be bypassed, otherwise nothing is
      #     built. The `name.nil?` conditional below currently does this.
      #
      #  TODO: Add test coverage for this behavior and ensure that `name.nil?`
      #  isn't fixing issue #701 by introducing untested regressions.
      #
      def build_attribute(name = nil, ransacker_args = [])
        Attribute.new(@context, name, ransacker_args).tap do |attribute|
          @context.bind(attribute, attribute.name)
          self.attributes << attribute if name.nil? || attribute.valid?
          if predicate && !negative?
            @context.lock_association(attribute.parent)
          end
        end
      end

      def build_value(val = nil)
        Value.new(@context, val).tap do |value|
          self.values << value
        end
      end

      def value
        if predicate.wants_array
          values.map { |v| v.cast(default_type) }
        else
          values.first.cast(default_type)
        end
      end

      def build(params)
        params.with_indifferent_access.each do |key, value|
          if key.match(/^(a|v|p|m)$/)
            self.send("#{key}=", value)
          end
        end

        self
      end

      def persisted?
        false
      end

      def key
        @key ||= attributes.map(&:name).join("_#{combinator}_") +
          "_#{predicate.name}"
      end

      def eql?(other)
        self.class == other.class &&
        self.attributes == other.attributes &&
        self.predicate == other.predicate &&
        self.values == other.values &&
        self.combinator == other.combinator
      end
      alias :== :eql?

      def hash
        [attributes, predicate, values, combinator].hash
      end

      def predicate_name=(name)
        self.predicate = Predicate.named(name)
        unless negative?
          attributes.each { |a| context.lock_association(a.parent) }
        end
        @predicate
      end
      alias :p= :predicate_name=

      def predicate_name
        predicate.name if predicate
      end
      alias :p :predicate_name

      def arel_predicate
        raise "not implemented"
      end

      def validated_values
        values.select { |v| predicate.validator.call(v.value) }
      end

      def casted_values_for_attribute(attr)
        validated_values.map { |v| v.cast(predicate.type || attr.type) }
      end

      def formatted_values_for_attribute(attr)
        formatted = casted_values_for_attribute(attr).map do |val|
          if attr.ransacker && attr.ransacker.formatter
            val = attr.ransacker.formatter.call(val)
          end
          val = predicate.format(val)
          val
        end
        if predicate.wants_array
          formatted
        else
          formatted.first
        end
      end

      def arel_predicate_for_attribute(attr)
        if predicate.arel_predicate === Proc
          values = casted_values_for_attribute(attr)
          unless predicate.wants_array
            values = values.first
          end
          predicate.arel_predicate.call(values)
        else
          predicate.arel_predicate
        end
      end

      def attr_value_for_attribute(attr)
        return attr.attr if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

        predicate.case_insensitive ? attr.attr.lower : attr.attr
      rescue
        attr.attr
      end


      def default_type
        predicate.type || (attributes.first && attributes.first.type)
      end

      def inspect
        data = [
          ['attributes'.freeze, a.try(:map, &:name)],
          ['predicate'.freeze, p],
          [Constants::COMBINATOR, m],
          ['values'.freeze, v.try(:map, &:value)]
        ]
        .reject { |e| e[1].blank? }
        .map { |v| "#{v[0]}: #{v[1]}" }
        .join(', '.freeze)
        "Condition <#{data}>"
      end

      def negative?
        predicate.negative?
      end

      private

      def valid_combinator?
        attributes.size < 2 || Constants::AND_OR.include?(combinator)
      end

    end
  end
end
