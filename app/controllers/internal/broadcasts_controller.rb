class Internal::BroadcastsController < Internal::ApplicationController
  layout "internal"
  # before_action :last_active_at
  # before_action :last_active_at, if: proc { Broadcast.active }

  def index
    @broadcasts = if params[:type_of]
                    Broadcast.where(type_of: params[:type_of].capitalize)
                  else
                    Broadcast.all
                  end.order(title: :asc)
  end

  def new
    @broadcast = Broadcast.new
  end

  def edit
    @broadcast = Broadcast.find(params[:id])
  end

  def create
    @broadcast = Broadcast.new(broadcast_params)

    if @broadcast.save
      flash[:success] = "Broadcast has been created!"
      redirect_to internal_broadcasts_path
    else
      flash[:danger] = @broadcast.errors.full_messages.to_sentence
      render new_internal_broadcast_path
    end
  end

  def update
    @broadcast = Broadcast.find(params[:id])

    if @broadcast.update(broadcast_params)
      flash[:success] = "Broadcast has been updated!"
      redirect_to internal_broadcasts_path
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

  def broadcast_params
    params.permit(:title, :processed_html, :type_of, :banner_style, :active, :last_active_at)
  end

  def authorize_admin
    authorize Broadcast, :access?, policy_class: InternalPolicy
  end

  # def last_active_at
  #   return unless Broadcast.last_active_at != created_at

  #   Broadcast.update(last_active_at: Time.zone.now)
  # end

  # def last_active_at
  #   # Displays a timestamp showing when the Broadcast was last set to "active"
  #   # active_broadcast = Broadcast.active
  #   # active_broadcasts.order("active DESC")
  #   Broadcast.update(last_active_at: Time.current)
  # end
end
