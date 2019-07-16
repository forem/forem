class ProMembershipsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :load_pro_membership, only: %i[edit update]
  after_action :verify_authorized, except: %i[show edit]

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

  def edit
    return redirect_to pro_membership_path, notice: "You are already a Pro member" if current_user.has_role?(:pro)
    return redirect_to pro_membership_path, notice: "You don't have a Pro Membership" unless @pro_membership

    @user = current_user
  end

  def update
    raise Pundit::NotAuthorizedError, "You don't have a Pro Membership" unless @pro_membership

    authorize @pro_membership

    if @pro_membership.update(update_params)
      redirect_to pro_membership_path, notice: "Your membership has been updated!"
    else
      render :edit
    end
  end

  private

  def load_pro_membership
    @pro_membership = current_user.pro_membership
  end

  def update_params
    params.require(:pro_membership).permit(:auto_recharge)
  end
end
