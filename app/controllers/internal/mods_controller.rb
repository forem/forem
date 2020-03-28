class Internal::ModsController < Internal::ApplicationController
  layout "internal"

  def index
    @mods = if params[:state] == "tag"
              User.with_role(:tag_moderator, :any).page(params[:page]).per(50)
            elsif params[:state] == "potential"
              User.without_role(:trusted).order("comments_count DESC").page(params[:page]).per(100)
            else
              User.with_role(:trusted).page(params[:page]).per(50)
            end

    return if params[:search].blank?

    @mods = @mods.where(
      "users.username ILIKE :search OR users.name ILIKE :search",
      search: "%#{params[:search]}%",
    )
  end

  def update
    @user = User.find(params[:id])

    AssignTagModerator.add_trusted_role(@user)

    render body: nil # No response needed at the moment
  end
end
