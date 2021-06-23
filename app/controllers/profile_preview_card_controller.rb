class ProfilePreviewCardController < ApplicationController
  layout false

  def show
    @actor = User.find_by(id: params[:userid])
    @preview_id = params[:preview_card_id]
  end
end
