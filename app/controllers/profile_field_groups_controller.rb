class ProfileFieldGroupsController < ApplicationController
  def index
    relation = ProfileFieldGroup.includes(:profile_fields)
    @profile_field_groups = onboarding? ? relation.onboarding : relation.all
    if onboarding?
      current_user.update(
        saw_onboarding: true,
        checked_code_of_conduct: true,
        checked_terms_and_conditions: true,
      )
    end
  end

  private

  def onboarding?
    params[:onboarding] == "true"
  end
end
