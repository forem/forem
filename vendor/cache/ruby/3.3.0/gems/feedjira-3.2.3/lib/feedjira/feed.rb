# frozen_string_literal: true

module Feedjira
  class Feed
    class << self
      def add_common_feed_element(element_tag, options = {})
        Feedjira.parsers.each do |k|
          k.element(element_tag, options)
        end
      end

      def add_common_feed_elements(element_tag, options = {})
        Feedjira.parsers.each do |k|
          k.elements(element_tag, options)
        end
      end

      def add_common_feed_entry_element(element_tag, options = {})
        call_on_each_feed_entry(:element, element_tag, options)
      end

      def add_common_feed_entry_elements(element_tag, options = {})
        call_on_each_feed_entry(:elements, element_tag, options)
      end

      private

      def call_on_each_feed_entry(method, *parameters)
        Feedjira.parsers.each do |klass|
          klass.sax_config.collection_elements.each_value do |value|
            collection_configs = value.select do |v|
              v.accessor == "entries" && v.data_class.is_a?(Class)
            end

            collection_configs.each do |config|
              config.data_class.send(method, *parameters)
            end
          end
        end
      end
    end
  end
end
