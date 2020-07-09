class PartnershipsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index]
  before_action :authenticate_user!, only: %i[create]
  after_action :verify_authorized

  def index
    skip_authorization
    set_surrogate_key_header "partnership-index"
  end

  def show
    skip_authorization
    @organizations = current_user&.admin_organizations
  end

  def create
    organization = Organization.find(sponsorship_params[:organization_id])
    authorize organization, :admin_of_org?

    level = sponsorship_params[:level]
    number_of_credits_needed = Sponsorship::CREDITS[level].to_i

    if %w[devrel media].include?(level)
      flash[:error] = "#{level.capitalize} sponsorship is not a self-serving one"
    elsif organization.credits.unspent.size < number_of_credits_needed
      flash[:error] = "Not enough credits"
    else
      sponsorable = Tag.find_by!(name: sponsorship_params[:tag_name]) if level == "tag"

      purchase_sponsorship(
        organization: organization,
        level: level,
        cost: number_of_credits_needed,
        sponsorable: sponsorable,
      )

      Slack::Messengers::Sponsorship.call(
        user: current_user,
        organization: organization,
        level: level,
        tag: sponsorable,
      )

      flash[:notice] = "You purchased a sponsorship"
    end

    redirect_back(fallback_location: partnerships_path)
  end

  private

  def sponsorship_params
    allowed_params = %i[organization_id level amount tag_name instructions]
    params.permit(allowed_params)
  end

  # NOTE: this should probably end up in a service object at some point
  def purchase_sponsorship(organization:, level:, cost:, sponsorable: nil)
    create_params = {
      user: current_user,
      level: level,
      status: :pending,
      sponsorable: sponsorable
    }
    # set expires_at for gold-silver-bronze and tag sponsorships
    if Sponsorship::METAL_LEVELS.include?(level) || sponsorable
      create_params[:expires_at] = 1.month.from_now
    end

    if sponsorship_params[:instructions]
      create_params[:instructions] = sponsorship_params[:instructions]
      # NOTE: why are we storing the updated_at of the instructions?
      create_params[:instructions_updated_at] = Time.current
    end

    ActiveRecord::Base.transaction do
      sponsorship = organization.sponsorships.create!(create_params)

      Credits::Buyer.call(
        purchaser: organization,
        purchase: sponsorship,
        cost: cost,
      )
    end
  end
end
