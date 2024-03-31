module Admin
  class ProfileFieldsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[
      input_type label active placeholder_text description profile_field_group_id display_area show_in_onboarding
    ].freeze
    layout "admin"

    def index
      @grouped_profile_fields = ProfileFieldGroup.includes(:profile_fields).order(:name)
      @ungrouped_profile_fields = ProfileField.where(profile_field_group_id: nil).order(:label)
    end

    def create
      add_result = ProfileFields::Add.call(profile_field_params)
      if add_result.success?
        profile_field = add_result.profile_field
        flash[:success] =
          I18n.t("admin.profile_fields_controller.created", field: profile_field.label)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: add_result.error_message)
      end
      redirect_to admin_profile_fields_path
    end

    def update
      profile_field = ProfileField.find(params[:id])
      if profile_field.update(profile_field_params)
        flash[:success] =
          I18n.t("admin.profile_fields_controller.updated", field: profile_field.label)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: profile_field.errors_as_sentence)
      end
      redirect_to admin_profile_fields_path
    end

    def destroy
      remove_result = ProfileFields::Remove.call(params[:id])
      if remove_result.success?
        profile_field = remove_result.profile_field
        flash[:success] =
          I18n.t("admin.profile_fields_controller.deleted", field: profile_field.label)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: remove_result.error_message)
      end
      redirect_to admin_profile_fields_path
    end

    private

    private_constant :ALLOWED_PARAMS

    def profile_field_params
      allowed_params = ALLOWED_PARAMS
      params.require(:profile_field).permit(allowed_params)
    end
  end
end
