class ProMembershipsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]
  after_action :verify_authorized

  def show; end

  def new; end

  def create
    authorize ProMembership

    if purchase_pro_membership
      redirect_to pro_membership_path, notice: "You are now a Pro!"
    else
      redirect_to pro_membership_path, flash: { error: "You don't have enough credits!" }
    end
  end

  def edit; end

  def update; end

  def destroy; end

  private

  def purchase_pro_membership
    cost = ProMembership::MONTHLY_COST

    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback if current_user.credits.unspent.size < cost

      pro_membership = ProMembership.create!(user: current_user)
      Credits::Buyer.call(
        purchaser: current_user,
        purchase: pro_membership,
        cost: cost,
      )
    end
  end
end
