class ProMembershipsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]
  after_action :verify_authorized, except: %i[show]

  def show
    @user = current_user
    @pro_membership = current_user&.pro_membership
  end

  # form to let the user subscribe?
  # probably it can be done embedding a form the show page with a confirmation
  def new; end

  def create
    authorize ProMembership

    if ProMemberships::Creator.call(current_user)
      redirect_to pro_membership_path, notice: "You are now a Pro!"
    else
      redirect_to pro_membership_path, flash: { error: "You don't have enough credits!" }
    end
  end

  # this is probably where the auto recharge top up configuration could go
  def edit; end

  # this is to update stuff, don't know what yet
  def update; end

  # probably we don't need this
  def destroy; end
end
