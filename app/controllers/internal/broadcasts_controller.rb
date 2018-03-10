class Internal::BroadcastsController < Internal::ApplicationController
  layout "internal"

  def create
    @broadcast = Broadcast.new(broadcast_params)
    if @broadcast.save
      # custom notifications not in use yet
      # if @broadcast.sent && @broadcast.type_of == "Announcement"
      #   # only send new notifications for announcements
      #   # onboarding notifications are automated
      #   Notification.send_all(@broadcast, @broadcast.type_of)
      # end
    end
    redirect_to "/internal/broadcasts"
  end

  def update
    @broadcast = Broadcast.find(params[:id])
    @broadcast.update(broadcast_params)
    # if @broadcast.save
    #   if @broadcast.sent && @broadcast.type_of == "Announcement"
    #    # see create action comments
    #     Notification.send_all(@broadcast, @broadcast.type_of)
    #   end
    # end
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
end
