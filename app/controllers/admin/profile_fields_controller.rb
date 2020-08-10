module Admin
  class ProfileFieldsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[
      input_type label active placeholder_text description
    ].freeze
    layout "admin"

    def index
      @profile_fields = ProfileField.all
    end

    def update
      profile_field = ProfileField.find(params[:id])
      if profile_field.update(profile_field_params)
        flash[:success] = "Profile field #{profile_field.label} updated"
      else
        flash[:error] = "Error: #{profile_field.errors_as_sentence}"
      end
      redirect_to admin_profile_fields_path
    end

    def create
      profile_field = ProfileField.new(profile_field_params)
      if profile_field.save
        flash[:success] = "Profile field #{profile_field.label} created"
      else
        flash[:error] = "Error: #{profile_field.errors_as_sentence}"
      end
      redirect_to admin_profile_fields_path
    end

    def destroy
      profile_field = ProfileField.find(params[:id])
      if profile_field.destroy
        flash[:success] = "Profile field #{profile_field.label} deleted"
      else
        flash[:error] = "Error: #{profile_field.errors_as_sentence}"
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
