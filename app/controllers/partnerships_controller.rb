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
  end

  def create
    @level = params[:sponsorship_level]
    @number_of_credits_needed = credits_for_level
    @organization = Organization.find(params[:organization_id])
    update_sponsorship_instructions
    authorize @organization, :admin_of_org?
    @available_org_credits = @organization.credits.where(spent: false)
    if @level == "tag"
      @tag = Tag.find_by(name: params[:tag_name])
      @tag.sponsor_organization_id = @organization.id
      slackbot_ping("@#{current_user.username} bought a ##{@tag.name} sponsorship for @#{@organization.username}")
      if @available_org_credits.size >= @number_of_credits_needed
        @tag.save!
        spend_credits
        redirect_back(fallback_location: "/partnerships")
      else
        raise "Not enough credits"
      end
    elsif @level == "media"
      # For now. Just ping slack.
      slackbot_ping("📹 @#{current_user.username} bought #{@number_of_credits_needed} media credits for @#{@organization.username}")
      if @available_org_credits.size >= @number_of_credits_needed
        spend_credits
        redirect_back(fallback_location: "/partnerships")
      end
    elsif @level == "editorial"
      SlackBot.ping(
        message: "@#{current_user.username} bought #{@number_of_credits_needed} credits for @#{@organization.username}",
        channel: "incoming-partners",
        username: "media_sponsor",
        icon_emoji: ":partyparrot:",
      )
      slackbot_ping("✍ @#{current_user.username} bought an editorial partnership for @#{@organization.username}")
      if @available_org_credits.size >= @number_of_credits_needed
        spend_credits
        redirect_back(fallback_location: "/partnerships")
      end
    else
      @organization.sponsorship_level = @level
      @organization.sponsorship_status = "pending"
      @organization.sponsorship_expires_at = (@organization.sponsorship_expires_at || Time.current) + 1.month
      slackbot_ping("@#{current_user.username} bought a #{@level} sponsorship for @#{@organization.username}")
      if @available_org_credits.size >= @number_of_credits_needed
        @organization.save!
        spend_credits
        redirect_back(fallback_location: "/partnerships")
      else
        raise "Not enough credits"
      end
    end
  end

  private

  def credits_for_level
    if @level == "gold"
      6000
    elsif @level == "silver"
      300
    elsif @level == "tag"
      500
    elsif @level == "bronze"
      50
    elsif @level == "editorial"
      500
    elsif @level == "media"
      params[:sponsorship_amount].to_i
    else
      raise "Invalid level"
    end
  end

  def update_sponsorship_instructions
    @organization.sponsorship_instructions = @organization.sponsorship_instructions + "\n---\n#{Time.current}\n---\n" + params[:sponsorship_instructions].to_s
    @organization.sponsorship_instructions_updated_at = Time.current
  end

  def spend_credits
    @available_org_credits.limit(@number_of_credits_needed).update_all(spent: true)
  end

  def slackbot_ping(text)
    SlackBot.ping(
      message: text,
      channel: "incoming-partners",
      username: "media_sponsor",
      icon_emoji: ":partyparrot:",
    )
  end
end
