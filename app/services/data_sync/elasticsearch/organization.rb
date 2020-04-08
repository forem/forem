module DataSync
  module Elasticsearch
    class Organization
      RELATED_DOCS = %i[
        articles
      ].freeze

      SHARED_TAG_FIELDS = %i[
        slug
        name
        profile_image
      ].freeze

      attr_accessor :organization, :updated_fields

      delegate :articles, to: :@organization

      def initialize(organization, updated_fields)
        @organization = organization
        @updated_fields = updated_fields.deep_symbolize_keys
      end

      def call
        return unless sync_needed?

        RELATED_DOCS.each do |relation_name|
          send(relation_name).find_each(&:index_to_elasticsearch)
        end
      end

      private

      def sync_needed?
        updated_fields.slice(*SHARED_TAG_FIELDS).any?
      end
    end
  end
end
