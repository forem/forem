module Internal
  class ProfileFieldsController < Internal::ApplicationController
    ALLOWED_PARAMS = %i[
      input_type label active placeholder_text description
    ].freeze
    layout "internal"

    def index
      @profile_fields = ProfileField.all
    end

    def update
      profile_field = ProfileField.find(params[:id])
      if profile_field.update(profile_field_params)
        flash[:success] = "Profile Field updated"
      else
        flash[:error] = "Profile Field error: #{profile_field.errors_as_sentence}"
      end
      redirect_to internal_profile_fields_path
    end

    def create
      profile_field = ProfileField.new(profile_field_params)
      if profile_field.save
        flash[:success] = "Profile Field created"
      else
        flash[:error] = "Profile Field error: #{profile_field.errors_as_sentence}"
      end
      redirect_to internal_profile_fields_path
    end

    def destroy
      profile_field = ProfileField.find(params[:id])
      if profile_field.destroy
        flash[:success] = "Profile Field destroyed"
      else
        flash[:error] = "Profile Field error: #{profile_field.errors_as_sentence}"
      end
      redirect_to internal_profile_fields_path
    end

    private

    private_constant :ALLOWED_PARAMS

    def profile_field_params
      allowed_params = ALLOWED_PARAMS
      params.require(:profile_field).permit(allowed_params)
    end
  end
end
