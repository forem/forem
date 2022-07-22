module Admin
  class WelcomeController < Admin::ApplicationController
    layout "admin"

    def index
      @daily_threads = if User.staff_account
                         Article.where("title LIKE 'Welcome Thread - %'").where(user_id: User.staff_account&.id)
                       else
                         []
                       end
    end

    def create
      welcome_thread = Article.create(
        body_markdown: welcome_thread_content,
        user: User.staff_account,
      )
      redirect_to "#{Addressable::URI.parse(welcome_thread.path).path}/edit"
    end

    private

    def welcome_thread_content
      I18n.t("admin.welcome_controller.thread_content",
             community: ::Settings::Community.community_name)
    end
  end
end
