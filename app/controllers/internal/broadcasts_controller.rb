module Internal
  class BroadcastsController < Internal::ApplicationController
    layout "internal"
    before_action :find_broadcastable, only: %i[create update]

    def index
      @broadcasts = if params[:broadcastable_type]
                      Broadcast.where(broadcastable_type: params[:broadcastable_type].capitalize)
                    else
                      Broadcast.all
                    end.order(title: :asc)
    end

    def show
      @broadcast = Broadcast.find(params[:id])
    end

    def new
      @broadcast = Broadcast.new
    end

    def edit
      @broadcast = Broadcast.find(params[:id])
    end

    def create
      # broadcast = Broadcast.new(broadcast_params)

      # broadcastable = case params[:broadcastable_type]
      #                 when "WelcomeNotification"
      #                   WelcomeNotification.create
      #                 when "Announcement"
      #                   Announcement.create
      #                 end

      # @broadcast = Broadcast.create(
      #   title: broadcast.title,
      #   processed_html: broadcast.processed_html,
      #   active: broadcast.active,
      #   banner_style: broadcast.banner_style,
      #   broadcastable: broadcastable,
      # )
      # @broadcast = @broadcastable.broadcasts.new(broadcast_params[:broadcasts])
      # @broadcast = broadcastable.broadcast.new(broadcast_params)
      # @broadcast = Broadcast.create(
      #   broadcast_params,
      #   broadcastable,
      # )
      # @broadcast = broadcast_params[:broadcastable_type].constantize.create
      @broadcast = @broadcastable.new(broadcast_params)

      if @broadcast.save
        flash[:success] = "Broadcast has been created!"
        redirect_to internal_broadcast_path(@broadcast)
      else
        flash[:danger] = @broadcast.errors.full_messages.to_sentence
        render new_internal_broadcast_path
      end
    end

    def update
      # @broadcast = Broadcast.find(params[:id])
      # @broadcast = Broadcast.find_by(broadcast_params[:broadcastable_id][:broadcastable_type])
      # @broadcast = @broadcastable.broadcast

      # broadcastable_type = case params[:broadcastable_type]
      #                      when "WelcomeNotification"
      #                        WelcomeNotification.find(params[:id])
      #                      when "Announcement"
      #                        Announcement.find(params[:id])
      #                      end

      # @broadcast = Broadcast.find(params[broadcastable])
      @broadcast = broadcastable_type.constantize.find_by(id: broadcastable_id)

      if @broadcast.update(broadcast_params)
        flash[:success] = "Broadcast has been updated!"
        redirect_to internal_broadcast_path(@broadcast)
      else
        flash[:danger] = @broadcast.errors.full_messages.to_sentence
        render :edit
      end
    end

    def destroy
      @broadcast = Broadcast.find(params[:id])

      if @broadcast.destroy
        flash[:success] = "Broadcast has been deleted!"
        redirect_to internal_broadcasts_path
      else
        flash[:danger] = "Something went wrong with deleting the broadcast."
        render :edit
      end
    end

    private

    def find_broadcastable
      broadcastable_type = case params[:broadcastable_type]
                           when "WelcomeNotification"
                             # WelcomeNotification.create
                             broadcast_params[:broadcastable_type].constantize.create
                           #  byebug
                           when "Announcement"
                             # Announcement.create
                             broadcast_params[:broadcastable_type].constantize.create
                           end

      # klass = broadcast_params[:broadcastable_type].constantize.create
      # byebug
      # @broadcastable = broadcastable_type.find(broadcastable_type.id)
      # @broadcastable = broadcastable_type.find(broadcast_params[:id])
      @broadcastable = broadcastable_type.where(id: broadcastable_type.id)
    end

    # def set_broadcastable
    #   @broadcastable = case params[:broadcastable_type]
    #                    when "WelcomeNotification"
    #                     WelcomeNotification.find(params[:welcome_notification_id])
    #                    when "Announcement"
    #                     Announcement.find(params[:announcement_id])
    #                    end
    # end

    def broadcast_params
      params.permit(:title, :processed_html, :broadcastable_type, :broadcastable_id, :banner_style, :active)
    end

    def authorize_admin
      authorize Broadcast, :access?, policy_class: InternalPolicy
    end
  end
end
