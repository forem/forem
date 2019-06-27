class SponsorshipsController < ApplicationController
  def new; end

  def create
    @level = params[:sponsorship_level]
    @number_of_credits_needed = credits_for_level
    @organization = Organization.find(params[:organization_id])
    @organization.sponsorship_level = @level
    @organization.sponsorship_expires_at = (@organization.sponsorship_expires_at || Time.current) + 1.month
    @available_org_credits = @organization.credits.where(spent: false)
    if @available_org_credits.size >= @number_of_credits_needed
      spend_credits
      @organization.save
      redirect_to "/sponsorships/new"
    else
      raise "Not enough credits"
    end
  end

  private

  def credits_for_level
    if @level == "gold"
      6000
    elsif @level == "silver"
      300
    elsif @level == "bronze"
      50
    else
      raise "Invalid level"
    end
  end

  def spend_credits
    @available_org_credits.limit(@number_of_credits_needed).update_all(spent: true)
  end
end
