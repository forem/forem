module Admin
  class ProfileFieldGroupsController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[
      name description
    ].freeze
    layout "admin"

    def update
      profile_field_group = ProfileFieldGroup.find(params[:id])
      if profile_field_group.update(profile_field_group_params)
        flash[:success] = "Group #{profile_field_group.name} updated"
      else
        flash[:error] = "Error: #{profile_field_group.errors_as_sentence}"
      end
      redirect_to admin_profile_fields_path
    end

    def create
      profile_field_group = ProfileFieldGroup.new(profile_field_group_params)
      if profile_field_group.save
        flash[:success] = "Successfully created group: #{profile_field_group.name}"
      else
        flash[:error] = "Error: #{profile_field_group.errors_as_sentence}"
      end
      redirect_to admin_profile_fields_path
    end

    def destroy
      profile_field_group = ProfileFieldGroup.find(params[:id])
      if profile_field_group.destroy
        flash[:success] = "Group #{profile_field_group.name} deleted"
      else
        flash[:error] = "Error: #{profile_field_group.errors_as_sentence}"
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
