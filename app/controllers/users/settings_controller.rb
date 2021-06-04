module Users
  class SettingsController < ApplicationController
    ALLOWED_PARAMS = %i[id
                        config_theme
                        config_font
                        config_navbar
                        editor_version
                        display_announcements
                        display_sponsors
                        experience_level
                        feed_fetched_at
                        feed_mark_canonical
                        feed_referential_link
                        feed_url
                        permit_adjacent_sponsors
                        user_id].freeze

    def update
      users_setting = Users::Setting.find(params[:id])
      users_setting.assign_attributes(users_setting_params)

      if users_setting.save
        # NOTE: [@msarit] this queues a job to fetch the feed each time the profile is updated, regardless if the user
        # explicitly requested "Feed fetch now" or simply updated any other field
        import_articles_from_feed(user)

        notice = "Your config has been updated. Refresh to see all changes."

        if users_setting.experience_level.present?
          cookies.permanent[:user_experience_level] =
            users_setting.experience_level.to_s
        end
        flash[:settings_notice] = notice
      else
        Honeycomb.add_field("error", users_setting.errors.messages.reject { |_, v| v.empty? })
        Honeycomb.add_field("errored", true)
        flash[:error] = @user.errors.full_messages.join(", ")
      end
      redirect_to "/settings/customization"
    end

    private

    def import_articles_from_feed(user)
      return if user.feed_url.blank?

      Feeds::ImportArticlesWorker.perform_async(nil, user.id)
    end

    def users_setting_params
      params.require(:users_setting).permit(ALLOWED_PARAMS)
    end
  end
end
