module Ransack
  class Predicate
    attr_reader :name, :arel_predicate, :type, :formatter, :validator,
                :compound, :wants_array, :case_insensitive

    class << self

      def names
        Ransack.predicates.keys
      end

      def named(name)
        Ransack.predicates[name.to_s]
      end

      def detect_and_strip_from_string!(str)
        detect_from_string str, chomp: true
      end

      def detect_from_string(str, chomp: false)
        return unless str

        Ransack.predicates.sorted_names_with_underscores.each do |predicate, underscored|
          if str.end_with? underscored
            str.chomp! underscored if chomp
            return predicate
          end
        end

        nil
      end

    end

    def initialize(opts = {})
      @name = opts[:name]
      @arel_predicate = opts[:arel_predicate]
      @type = opts[:type]
      @formatter = opts[:formatter]
      @validator = opts[:validator] ||
        lambda { |v| v.respond_to?(:empty?) ? !v.empty? : !v.nil? }
      @compound = opts[:compound]
      @wants_array = opts.fetch(:wants_array,
        @compound || Constants::IN_NOT_IN.include?(@arel_predicate))
      @case_insensitive = opts[:case_insensitive]
    end

    def eql?(other)
      self.class == other.class &&
      self.name == other.name
    end
    alias :== :eql?

    def hash
      name.hash
    end

    def format(val)
      if formatter
        formatter.call(val)
      else
        val
      end
    end

    def validate(vals, type = @type)
      vals.any? { |v| validator.call(type ? v.cast(type) : v.value) }
    end

    def negative?
      @name.include?("not_".freeze)
    end

  end
end
