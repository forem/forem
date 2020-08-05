module Internal
  class ProfileFieldsController < Internal::ApplicationController
    layout "internal"

    def index
      @profile_fields = ProfileField.all
    end

    def update
      @profile_fields = ProfileField.find(params[:id])
      @profile_fields.update!(profile_field_params)
      redirect_to internal_profile_fields_path
    end

    def create
      @profile_field = ProfileField.create(profile_field_params)
      redirect_to internal_profile_fields_path
    end

    def destroy
      @profile_field = ProfileField.find(params[:id])
      @profile_field.destroy
      redirect_to internal_profile_fields_path
    end

    private

    def profile_field_params
      allowed_params = %i[input_type label active placeholder_text description]
      params.require(:profile_field).permit(allowed_params)
    end
  end
end
