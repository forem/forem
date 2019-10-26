class Internal::BroadcastsController < Internal::ApplicationController
  layout "internal"

  def create
    @broadcast = Broadcast.new(broadcast_params)
    redirect_to "/internal/broadcasts"
  end

  def update
    @broadcast = Broadcast.find(params[:id])
    @broadcast.update(broadcast_params)
    redirect_to "/internal/broadcasts"
  end

  def new
    @broadcast = Broadcast.new
  end

  def edit
    @broadcast = Broadcast.find(params[:id])
  end

  def index
    @broadcasts = Broadcast.all
  end

  private

  def broadcast_params
    params.permit(:title, :processed_html, :type_of, :sent)
    # left out body_markdown and processed_html attributes
    #   until we decide we're using them
  end

  def authorize_admin
    authorize Broadcast, :access?, policy_class: InternalPolicy
  end
end
