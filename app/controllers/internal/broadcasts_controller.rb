class Internal::BroadcastsController < Internal::ApplicationController
  layout "internal"

  def create
    @broadcast = Broadcast.create!(broadcast_params)
    flash[:success] = "Broadcast has been created!"
    redirect_to "/internal/broadcasts"
  rescue ActiveRecord::RecordInvalid => e
    flash[:danger] = e.message
    redirect_to "/internal/broadcasts"
  end

  def update
    @broadcast = Broadcast.find_by!(id: params[:id])
    @broadcast.update!(broadcast_params)
    flash[:success] = "Broadcast has been updated!"
    redirect_to "/internal/broadcasts"
  rescue ActiveRecord::RecordInvalid => e
    flash[:danger] = e.message
    redirect_to "/internal/broadcasts/#{params[:id]}/edit"
  end

  def new
    @broadcast = Broadcast.new
  end

  def edit
    @broadcast = Broadcast.find_by!(id: params[:id])
  end

  def index
    @broadcasts = if params[:type_of]
                    Broadcast.where(type_of: params[:type_of].capitalize)
                  else
                    Broadcast.all
                  end.order(title: :asc)
  end

  def destroy
    broadcast = Broadcast.find_by!(id: params[:id])
    if broadcast.destroy
      flash[:success] = "Broadcast has been deleted!"
      redirect_to "/internal/broadcasts"
    else
      flash[:danger] = "Something went wrong with deleting the broadcast."
      redirect_to "/internal/broadcasts/#{params[:id]}/edit"
    end
  end

  private

  def broadcast_params
    params.permit(:title, :processed_html, :type_of, :banner_style, :active)
  end

  def authorize_admin
    authorize Broadcast, :access?, policy_class: InternalPolicy
  end
end
