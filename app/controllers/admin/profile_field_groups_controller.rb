module Admin
  class ProfileFieldGroupsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[
      name description
    ].freeze
    layout "admin"

    def create
      @profile_field_group = ProfileFieldGroup.new(profile_field_group_params)
      if @profile_field_group.save
        flash[:success] = "Successfully created group: #{@profile_field_group.name}"
      else
        flash[:error] = @profile_field_group.errors.full_messages
      end
      redirect_to admin_profile_fields_path
    end

    private

    private_constant :ALLOWED_PARAMS

    def profile_field_group_params
      allowed_params = ALLOWED_PARAMS
      params.require(:profile_field_group).permit(allowed_params)
    end
  end
end
