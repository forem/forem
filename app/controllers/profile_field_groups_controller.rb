class ProfileFieldGroupsController < ApplicationController
  def index
    relation = ProfileFieldGroup.includes(:profile_fields)
    @profile_field_groups = onboarding? ? relation.onboarding : relation.all
  end

  private

  def onboarding?
    params[:onboarding] == "true"
  end
end
