module Admin
  class ModsController < Admin::ApplicationController
    layout "admin"

    INDEX_ATTRIBUTES = %i[
      id
      username
      comments_count
      badge_achievements_count
      last_comment_at
    ].freeze

    def index
      @mods = Admin::ModeratorsQuery.call(
        relation: User.select(INDEX_ATTRIBUTES),
        options: permitted_params,
      ).page(params[:page]).per(50)
    end

    def update
      @user = User.find(params[:id])

      TagModerators::AddTrustedRole.call(@user)

      redirect_to admin_mods_path(state: :potential),
                  flash: { success: I18n.t("admin.mods_controller.trusted",
                                           username: @user.username) }
    end

    private

    def permitted_params
      params.permit(:state, :search, :page)
    end
  end
end
