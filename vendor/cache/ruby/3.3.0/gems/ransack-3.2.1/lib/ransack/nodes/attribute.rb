module Ransack
  module Nodes
    class Attribute < Node
      include Bindable

      attr_reader :name, :ransacker_args

      delegate :blank?, :present?, :to => :name
      delegate :engine, :to => :context

      def initialize(context, name = nil, ransacker_args = [])
        super(context)
        self.name = name unless name.blank?
        @ransacker_args = ransacker_args
      end

      def name=(name)
        @name = name
      end

      def valid?
        bound? && attr &&
        context.klassify(parent).ransackable_attributes(context.auth_object)
        .include?(attr_name.split('.').last)
      end

      def associated_collection?
        parent.respond_to?(:reflection) && parent.reflection.collection?
      end

      def type
        if ransacker
          ransacker.type
        else
          context.type_for(self)
        end
      end

      def eql?(other)
        self.class == other.class &&
        self.name == other.name
      end
      alias :== :eql?

      def hash
        self.name.hash
      end

      def persisted?
        false
      end

      def inspect
        "Attribute <#{name}>"
      end

    end
  end
end
