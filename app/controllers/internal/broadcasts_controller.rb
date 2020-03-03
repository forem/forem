class Internal::BroadcastsController < Internal::ApplicationController
  layout "internal"

  def create
    @broadcast = Broadcast.create!(broadcast_params)
    redirect_to "/internal/broadcasts"
  end

  def update
    @broadcast = Broadcast.find_by!(id: params[:id])
    @broadcast.update!(broadcast_params)
    redirect_to "/internal/broadcasts"
  end

  def new
    @broadcast = Broadcast.new
  end

  def edit
    @broadcast = Broadcast.find_by!(id: params[:id])
  end

  def index
    @broadcasts = Broadcast.all
  end

  private

  def broadcast_params
    params.permit(:title, :processed_html, :type_of, :active)
  end

  def authorize_admin
    authorize Broadcast, :access?, policy_class: InternalPolicy
  end
end
