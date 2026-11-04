# Manages the GitHub organizations whose public repositories a user can pin.
class GithubOrganizationsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  # NOTE: handlers declared last take precedence, so the specific ones go last.
  rescue_from Github::Errors::Error, Faraday::Error do
    render json: { error: I18n.t("github_organizations_controller.github_unavailable") },
           status: :service_unavailable
  end

  rescue_from Github::Errors::Unauthorized, Github::Errors::AccountSuspended do |e|
    render json: { error: I18n.t("github_organizations_controller.github_unauthorized", e_message: e.message) },
           status: :unauthorized
  end

  def create
    authorize GithubRepo, :manage_organizations?

    setting = current_user.setting
    name = organization_param

    # Cheap checks and the GitHub request come first, so no lock is held during the request.
    errors = Users::Setting.github_organization_errors(setting.github_organizations + [name])
    return render json: { error: errors.to_sentence }, status: :unprocessable_entity if errors.any?
    return organization_not_found unless organization_exists?(name)

    # The lock serializes concurrent changes, so none of them overwrites the organizations of another.
    setting.with_lock do
      setting.github_organizations += [name]
      # Validated again, as the organizations may have changed while GitHub was being asked.
      return render_validation_errors(setting) unless setting.valid?

      setting.save!
      render json: { organizations: setting.github_organizations }, status: :created
    end
  end

  def destroy
    authorize GithubRepo, :manage_organizations?

    setting = current_user.setting
    organization = nil
    # Removing the organization and unpinning its repositories succeed or fail together.
    setting.with_lock do
      organization = setting.github_organizations.find { |name| name.casecmp?(params[:id]) }
      next unless organization

      setting.update!(github_organizations: setting.github_organizations - [organization])
      unpin_repositories_of(organization)
    end
    return organization_not_found unless organization

    render json: { organizations: setting.github_organizations }
  end

  private

  def organization_param
    params.require(:organization).to_s.strip
  end

  def organization_exists?(name)
    Github::OauthClient.for_user(current_user).organization(name)
    true
  rescue Github::Errors::NotFound
    false
  end

  # The repositories of a removed organization can no longer be listed, so the
  # user would not be able to unpin them by themselves.
  def unpin_repositories_of(organization)
    repos = current_user.github_repos.select { |repo| repo.owner_login&.casecmp?(organization) }
    return if repos.empty?

    repos.each(&:destroy!)
    current_user.touch(:github_repos_updated_at)
  end

  def organization_not_found
    render json: { error: I18n.t("github_organizations_controller.organization_not_found") }, status: :not_found
  end

  def render_validation_errors(setting)
    render json: { error: setting.errors.map(&:message).to_sentence }, status: :unprocessable_entity
  end
end
