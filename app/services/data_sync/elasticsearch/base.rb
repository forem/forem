module DataSync
  module Elasticsearch
    class Base
      attr_reader :updated_record

      def initialize(updated_record)
        @updated_record = updated_record
      end

      def call
        return unless sync_needed?

        sync_related_documents
      end

      private

      def sync_needed?
        updated_fields.slice(*self.class::SHARED_FIELDS).any?
      end

      def sync_related_documents
        self.class::RELATED_DOCS.each do |relation_name|
          __send__(relation_name).find_each(&:index_to_elasticsearch)
        end
      end

      def updated_fields
        updated_record.saved_changes
      end
    end
  end
end
