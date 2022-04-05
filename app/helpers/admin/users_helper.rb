module Admin
  module UsersHelper
    def format_last_activity_timestamp(timestamp)
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
      elsif user.trusted?
        "Tag moderator"
      else
        "Regualr member"
      end
    end
  end
end
