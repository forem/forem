module Admin
  class PushNotificationTargetsController < Admin::ApplicationController
    layout "admin"

    def index
      @push_notification_targets = PushNotificationTarget.all_targets
    end

    def new
      @push_notification_target = PushNotificationTarget.new
    end

    def edit
      @push_notification_target = PushNotificationTarget.find(params[:id])

      # Forem apps shouldn't be modified by creators
      redirect_to admin_push_notification_targets_path if @push_notification_target.forem_app?
    end

    def create
      @push_notification_target = PushNotificationTarget.new(push_notification_target_params)
      @push_notification_target.active = true

      if @push_notification_target.forem_app?
        # New Forem apps shouldn't be created by creators
        redirect_to admin_push_notification_targets_path
      elsif @push_notification_target.save
        flash[:success] = "#{@push_notification_target.app_bundle} has been created!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = @push_notification_target.errors_as_sentence
        render :new
      end
    end

    def update
      @push_notification_target = PushNotificationTarget.find(params[:id])

      if @push_notification_target.forem_app?
        # Forem apps shouldn't be modified by creators
        redirect_to admin_push_notification_targets_path
      elsif @push_notification_target.update(push_notification_target_params)
        flash[:success] = "#{@push_notification_target.app_bundle} has been updated!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = @push_notification_target.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @push_notification_target = PushNotificationTarget.find(params[:id])

      if @push_notification_target.forem_app?
        # Forem apps shouldn't be destroyed by creators
        redirect_to admin_push_notification_targets_path
      elsif @push_notification_target.destroy
        flash[:success] = "#{@push_notification_target.app_bundle} has been deleted!"
        redirect_to admin_push_notification_targets_path
      else
        flash[:danger] = "Something went wrong with deleting #{@push_notification_target.app_bundle}."
        render :edit
      end
    end

    private

    def authorize_admin
      authorize PushNotificationTarget, :access?, policy_class: InternalPolicy
    end

    def push_notification_target_params
      params.permit(:app_bundle, :platform, :auth_key)
    end
  end
end
