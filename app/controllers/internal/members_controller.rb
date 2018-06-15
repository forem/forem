class Internal::MembersController < Internal::ApplicationController
  layout "internal"

  def index
    # with_role and with_any_role return an array and not an ActiveRecord collection
    @users = case params[:state]
             when "by-scholars"
               User.with_role(:workshop_pass).sort_by(&:name)
             when "by-members"
               User.with_any_role(:level_1_member,
                                  :level_2_member,
                                  :level_3_member,
                                  :level_4_member,
                                  :triple_unicorn_member).sort_by(&:name)
             else # members and scholars
               User.with_any_role(:level_1_member,
                                  :level_2_member,
                                  :level_3_member,
                                  :level_4_member,
                                  :triple_unicorn_member,
                                  :workshop_pass).sort_by(&:name)
             end
  end
end
