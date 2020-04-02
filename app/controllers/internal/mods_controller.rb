class Internal::ModsController < Internal::ApplicationController
  layout "internal"

  INDEX_ATTRIBUTES = %i[
    id
    username
    comments_count
    badge_achievements_count
    last_comment_at
  ].freeze

  def index
    @mods = Internal::ModeratorsQuery.call(
      relation: User.select(INDEX_ATTRIBUTES),
      options: permitted_params,
    ).page(params[:page]).per(50)
  end

  def update
    @user = User.find(params[:id])

    AssignTagModerator.add_trusted_role(@user)

    redirect_to internal_mods_path(state: :potential),
                flash: { success: "#{@user.username} now has Trusted role!" }
  end

  private

  def permitted_params
    params.permit(:state, :search, :page)
  end
end
