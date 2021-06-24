class ProfilePreviewCardController < ApplicationController
  layout false

  def show
    @actor = User.find_by(id: params[:user_id])
    @preview_id = params[:preview_card_id]
  end
end
