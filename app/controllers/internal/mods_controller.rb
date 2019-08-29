class Internal::ModsController < Internal::ApplicationController
  layout "internal"

  def index
    @mods = if params[:state] == "tag"
              User.with_role(:tag_moderator, :any).page(params[:page]).per(50).includes(:notes)
            elsif params[:state] == "potential"
              User.order("comments_count DESC").page(params[:page]).per(100).includes(:notes)
            else
              User.with_role(:trusted).page(params[:page]).per(50).includes(:notes)
            end
    @mods = @mods.where("users.username ILIKE :search OR users.name ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def update
    @user = User.find(params[:id])
    AssignTagModerator.add_trusted_role(@user)
    render body: nil # No response needed at the moment
  end
end
