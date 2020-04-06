class Internal::ModsController < Internal::ApplicationController
  layout "internal"

  DEFAULT_PER_PAGE = 50

  def index
    @mods = Internal::ModeratorsQuery.call(options: permitted_params).page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  def update
    @user = User.find(params[:id])

    AssignTagModerator.add_trusted_role(@user)

    redirect_to internal_mods_path(state: :potential),
                flash: { success: "#{@user.username} now has Trusted role!" }
  end

  private

  def permitted_params
    params.permit(:state, :search, :page).merge(per_page: DEFAULT_PER_PAGE)
  end
end
