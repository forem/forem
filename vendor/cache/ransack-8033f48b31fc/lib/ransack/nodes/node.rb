module Ransack
  module Nodes
    class Node
      attr_reader :context
      delegate :contextualize, :to => :context
      class_attribute :i18n_words
      class_attribute :i18n_aliases
      self.i18n_words = []
      self.i18n_aliases = {}

      class << self
        def i18n_word(*args)
          self.i18n_words += args.map(&:to_s)
        end

        def i18n_alias(opts = {})
          self.i18n_aliases.merge! Hash[opts.map { |k, v| [k.to_s, v.to_s] }]
        end
      end

      def initialize(context)
        @context = context
      end

      def translate(key, options = {})
        key = i18n_aliases[key.to_s] if i18n_aliases.has_key?(key.to_s)
        if i18n_words.include?(key.to_s)
          Translate.word(key)
        end
      end

    end
  end
end
