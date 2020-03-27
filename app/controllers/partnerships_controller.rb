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
    @organization = Organization.find(sponsorship_params[:organization_id])
    authorize @organization, :admin_of_org?

    @level = sponsorship_params[:level]
    @number_of_credits_needed = Sponsorship::CREDITS[@level]
    if @level == "media" && @number_of_credits_needed.nil?
      @number_of_credits_needed = sponsorship_params[:amount].to_i
    end
    @available_org_credits = @organization.credits.unspent

    # NOTE: this should probably be a redirect with a notice
    raise "Not enough credits" unless @available_org_credits.size >= @number_of_credits_needed

    tag_sponsorship = @level == "tag"
    @tag = Tag.find_by!(name: sponsorship_params[:tag_name]) if tag_sponsorship

    sponsorable = tag_sponsorship ? @tag : nil
    purchase_sponsorship(
      organization: @organization,
      level: @level,
      cost: @number_of_credits_needed,
      sponsorable: sponsorable,
    )

    Slack::Messengers::Sponsorship.call(
      user: current_user,
      organization: @organization,
      level: @level,
      tag: @tag,
    )

    redirect_back(fallback_location: partnerships_path)
  end

  private

  def sponsorship_params
    allowed_params = %i[organization_id level amount tag_name instructions]
    params.permit(allowed_params)
  end

  # NOTE: this should probably end up in a service object at some point
  def purchase_sponsorship(organization:, level:, cost:, sponsorable: nil)
    expires_at = Sponsorship::LEVELS_WITH_EXPIRATION.include?(level) ? 1.month.from_now : nil
    create_params = {
      user: current_user,
      level: level,
      status: :pending,
      expires_at: expires_at
    }
    if sponsorable
      create_params[:sponsorable] = sponsorable
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
