module Notifications
  module OrganizationDeverification
    class Send
      def self.call(...)
        new(...).call
      end

      def initialize(organization)
        @organization = organization
      end

      delegate :organization_data, to: Notifications

      def call
        action = "Deverification::#{Time.current.to_f}"
        json = json_data

        # Org-level notification (visible in org notifications tab)
        Notification.create(
          organization_id: organization.id,
          notifiable: organization,
          action: action,
          json_data: json,
        )

        # User-level notifications for each admin (triggers bell icon count)
        admin_user_ids = organization.organization_memberships
          .where(type_of_user: "admin").pluck(:user_id)
        admin_user_ids.each do |uid|
          Notification.create(
            user_id: uid,
            notifiable: organization,
            action: action,
            json_data: json,
          )
        end
      end

      private

      attr_reader :organization

      def json_data
        {
          organization: organization_data(organization),
        }
      end
    end
  end
end
