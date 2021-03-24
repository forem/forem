module Admin
  class BroadcastsController < Admin::ApplicationController
    layout "admin"

    def index
      @broadcasts = if params[:type_of]
                      Broadcast.where(type_of: params[:type_of].capitalize)
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
      @broadcast = Broadcast.new(broadcast_params)

      if @broadcast.save
        flash[:success] = "Broadcast has been created!"
        redirect_to admin_broadcast_path(@broadcast)
      else
        flash[:danger] = @broadcast.errors.full_messages.to_sentence
        render :new
      end
    end

    def update
      @broadcast = Broadcast.find(params[:id])

      if @broadcast.update(broadcast_params)
        flash[:success] = "Broadcast has been updated!"
        redirect_to admin_broadcast_path(@broadcast)
      else
        flash[:danger] = @broadcast.errors.full_messages.to_sentence
        render :edit
      end
    end

    def destroy
      @broadcast = Broadcast.find(params[:id])

      if @broadcast.destroy
        flash[:success] = "Broadcast has been deleted!"
        redirect_to admin_broadcasts_path
      else
        flash[:danger] = "Something went wrong with deleting the broadcast."
        render :edit
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
end
