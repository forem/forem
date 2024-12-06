require 'i18n'

I18n.load_path += Dir[
  File.join(File.dirname(__FILE__), 'locale'.freeze, '*.yml'.freeze)
]

module Ransack
  module Translate
    class << self
      def word(key, options = {})
        I18n.translate(:"ransack.#{key}", default: key.to_s)
      end

      def predicate(key, options = {})
        I18n.translate(:"ransack.predicates.#{key}", default: key.to_s)
      end

      def attribute(key, options = {})
        unless context = options.delete(:context)
          raise ArgumentError, "A context is required to translate attributes"
        end

        original_name = key.to_s
        base_class = context.klass
        base_ancestors = base_class.ancestors.select {
          |x| x.respond_to?(:model_name)
        }
        attributes_str = original_name.dup # will be modified by ⬇
        predicate = Predicate.detect_and_strip_from_string!(attributes_str)
        attribute_names = attributes_str.split(/_and_|_or_/)
        combinator = attributes_str =~ /_and_/ ? :and : :or
        defaults = base_ancestors.map do |klass|
          "ransack.attributes.#{i18n_key(klass)}.#{original_name}".to_sym
        end
        defaults << options.delete(:default) if options[:default]

        translated_names = attribute_names.map do |name|
          attribute_name(context, name, options[:include_associations])
        end

        interpolations = {
          attributes: translated_names.join(" #{Translate.word(combinator)} ")
        }

        if predicate
          defaults << "%{attributes} %{predicate}".freeze
          interpolations[:predicate] = Translate.predicate(predicate)
        else
          defaults << "%{attributes}".freeze
        end

        options.reverse_merge! count: 1, default: defaults
        I18n.translate(defaults.shift, **options.merge(interpolations))
      end

      def association(key, options = {})
        unless context = options.delete(:context)
          raise ArgumentError, "A context is required to translate associations"
        end

        defaults =
          if key.blank?
            [:"ransack.models.#{i18n_key(context.klass)}",
             :"#{context.klass.i18n_scope}.models.#{i18n_key(context.klass)}"]
          else
            [:"ransack.associations.#{i18n_key(context.klass)}.#{key}"]
          end
        defaults << context.traverse(key).model_name.human
        options = { :count => 1, :default => defaults }
        I18n.translate(defaults.shift, **options)
      end

      private

      def attribute_name(context, name, include_associations = nil)
        @context, @name = context, name
        @assoc_path = context.association_path(name)
        @attr_name = @name.sub(/^#{@assoc_path}_/, ''.freeze)
        associated_class = @context.traverse(@assoc_path) if @assoc_path.present?
        @include_associated = include_associations && associated_class

        defaults = default_attribute_name << fallback_args
        options = { count: 1, default: defaults }
        interpolations = build_interpolations(associated_class)

        I18n.translate(defaults.shift, **options.merge(interpolations))
      end

      def default_attribute_name
        ["ransack.attributes.#{i18n_key(@context.klass)}.#{@name}".to_sym]
      end

      def fallback_args
        if @include_associated
          '%{association_name} %{attr_fallback_name}'.freeze
        else
          '%{attr_fallback_name}'.freeze
        end
      end

      def build_interpolations(associated_class)
        {
          attr_fallback_name: attr_fallback_name(associated_class),
          association_name: association_name
        }.reject { |_, value| value.nil? }
      end

      def attr_fallback_name(associated_class)
        I18n.t(
          :"ransack.attributes.#{fallback_class(associated_class)}.#{@attr_name}",
          default: default_interpolation(associated_class)
        )
      end

      def fallback_class(associated_class)
        i18n_key(associated_class || @context.klass)
      end

      def association_name
        association(@assoc_path, context: @context) if @include_associated
      end

      def default_interpolation(associated_class)
        [
          associated_attribute(associated_class),
          ".attributes.#{@attr_name}".to_sym,
          @attr_name.humanize
        ].flatten
      end

      def associated_attribute(associated_class)
        if associated_class
          translated_attribute(associated_class)
        else
          translated_ancestor_attributes
        end
      end

      def translated_attribute(associated_class)
        key = "#{associated_class.i18n_scope}.attributes.#{
        i18n_key(associated_class)}.#{@attr_name}"
        ["#{key}.one".to_sym, key.to_sym]
      end

      def translated_ancestor_attributes
        @context.klass.ancestors
          .select { |ancestor| ancestor.respond_to?(:model_name) }
          .map { |ancestor| translated_attribute(ancestor) }
      end

      def i18n_key(klass)
        raise "not implemented"
      end
    end
  end
end
