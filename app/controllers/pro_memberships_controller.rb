class ProMembershipsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  after_action :verify_authorized, except: %i[show]

  def show
    @user = current_user
    @pro_membership = current_user&.pro_membership
  end

  def create
    authorize ProMembership

    if ProMemberships::Creator.call(current_user)
      redirect_to pro_membership_path, notice: "You are now a Pro!"
    else
      redirect_to pro_membership_path, flash: { error: "You don't have enough credits!" }
    end
  end

  # these two should contain the logic to activate or disable the auto recharge feature
  def edit; end

  def update
    pro_membership = current_user.pro_membership

    raise Pundit::NotAuthorizedError unless pro_membership

    authorize pro_membership

    if pro_membership.update(update_params)
      redirect_to pro_membership_path, notice: "Your membership has been updated!"
    else
      render :new
    end
  end

  private

  def update_params
    params.require(:pro_membership).permit(:auto_recharge)
  end
end
