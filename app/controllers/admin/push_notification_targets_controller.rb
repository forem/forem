module Admin
  class PushNotificationTargetsController < Admin::ApplicationController
    layout "admin"

    def index
      @targets = PushNotifications::Targets::FetchAll.call
    end

    def new
      @target = PushNotificationTarget.new
    end

    def edit
      @target = PushNotificationTarget.find(params[:id])
      authorize @target
    end

    def create
      @target = PushNotificationTarget.new(push_notification_target_params)
      @target.active = true
      authorize @target

      if @target.save
        flash[:success] = "#{@target.app_bundle} has been created!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = @target.errors_as_sentence
        render :new
      end
    end

    def update
      @target = PushNotificationTarget.find(params[:id])
      authorize @target

      if @target.update(push_notification_target_params)
        flash[:success] = "#{@target.app_bundle} has been updated!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = @target.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @target = PushNotificationTarget.find(params[:id])
      authorize @target

      if @target.destroy
        flash[:success] = "#{@target.app_bundle} has been deleted!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = "Something went wrong with deleting #{@target.app_bundle}."
        render :edit
      end
    end

    private

    def push_notification_target_params
      params.permit(:app_bundle, :platform, :auth_key)
    end
  end
end
