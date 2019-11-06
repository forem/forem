class ProMembershipsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :load_pro_membership, only: %i[update]
  after_action :verify_authorized, except: %i[show]

  def show
    @user = current_user
    @pro_membership = current_user&.pro_membership
  end

  def create
    authorize ProMembership

    if ProMemberships::Creator.call(current_user)
      flash[:settings_notice] = "You are now a Pro!"
    else
      flash[:error] = "You don't have enough credits!"
    end

    redirect_to user_settings_path("pro-membership")
  end

  def update
    raise Pundit::NotAuthorizedError, "You don't have a Pro Membership" unless @pro_membership

    authorize @pro_membership

    if @pro_membership.update(update_params)
      flash[:settings_notice] = "Your membership has been updated!"
    else
      flash[:error] = "An error has occurred while updating your membership!"
    end

    redirect_to user_settings_path("pro-membership")
  end

  private

  def load_pro_membership
    @pro_membership = current_user.pro_membership
  end

  def update_params
    params.require(:pro_membership).permit(:auto_recharge)
  end
end
