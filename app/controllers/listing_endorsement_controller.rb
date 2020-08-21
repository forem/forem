class ListingEndorsementsController < ApplicationController
  before_action :raise_suspended, only: %i[create update]
  before_action :authenticate_user!, only: %i[create update]
  after_action :verify_authorized, only: %i[update]

  def create
    @endorsement = ListingEndorsement.create(content: params[:content],
                                             user_id: current_user.id,
                                             classified_listing_id: params[:classified_listing_id])
    if @endorsement.persisted?
      Notification.send_new_endorsement_notifications_without_delay(@endorsement)
      render json: { status: "created" }, status: :ok
    else
      render json: { error: "an error occured with the endorsement" }, status: :unprocessable_entity
    end
  end

  def update
    @endorsement = ListingEndorsement.find(params[:id])

    authorize @endorsement

    @endorsement.update(approved: true) unless @endorsement.approved
  end
end
