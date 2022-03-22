module Exporter
  module Admin
    class Users
      ATTRIBUTES = %w[
        created_at
        last_article_at
        latest_article_updated_at
        last_comment_at
        profile_updated_at
        updated_at
        name
        username
        email
      ].freeze

      def self.export
        csvify
      end

      private

      def allowed_attributes
        general_attributes | time_attributes
      end

      def time_attributes
        %i[
          created_at
          last_article_at
          latest_article_updated_at
          last_comment_at
          last_reacted_at
          profile_updated_at
          updated_at
        ]
      end

      def general_attributes
        %i[
          id
          name
          username
          email
        ]
      end

      def csvify
        CSV.generate do |csv|
          csv << allowed_attributes.map(&:to_s)
          User.select(allowed_attributes).find_each do |user|
            values = user.attributes.values.map do |value|
              if value.blank?
                "<blank>"
              elsif value.class.name.include? "Time"
                "'#{value}'"
              else
                value
              end
            end
            csv << values
          end
        end
      end
    end
  end
end
