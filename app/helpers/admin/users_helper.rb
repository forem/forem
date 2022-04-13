module Admin
  module UsersHelper
    def format_last_activity_timestamp(timestamp)
      return if timestamp.blank?

      if timestamp.today?
        "Today, #{timestamp.strftime('%d %b')}"
      elsif timestamp.yesterday?
        "Yesterday, #{timestamp.strftime('%d %b')}"
      else
        timestamp.strftime("%d %b, %Y")
      end
    end

    def cascading_high_level_roles(user)
      if user.super_admin?
        "Super Admin"
      elsif user.admin?
        "Admin"
      elsif user.single_resource_admin_for?(:any)
        "Resource Admin"
      end
    end

    def format_role_tooltip(user)
      if user.super_admin?
        "Super Admin"
      elsif user.admin?
        "Admin"
      elsif user.single_resource_admin_for?(:any)
        "Resource Admin: #{user.roles.pluck(:resource_type).compact.join(', ')}"
      end
    end

    def user_status(user)
      if user.suspended?
        "Suspended"
      elsif user.warned?
        "Warned"
      elsif user.comment_suspended?
        "Comment Suspended"
      elsif user.trusted?
        "Trusted"
      else
        "Good Standing"
      end
    end
  end
end
