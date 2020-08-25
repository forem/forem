class ListingEndorsementsController < ApplicationController
  before_action :raise_suspended, only: %i[create update]
  before_action :authenticate_user!, only: %i[create update]
  after_action :verify_authorized, only: %i[update]

  def create
    endorsement = ListingEndorsement.create(content: params[:content],
                                            user_id: current_user.id,
                                            classified_listing_id: params[:classified_listing_id])
    if endorsement.persisted?
      Notification.send_new_endorsement_notifications_without_delay(endorsement)
      render json: "The endorsement has been made", status: :created
    else
      render json: { error: endorsement.errors_as_sentence }, status: :unprocessable_entity
    end
  end

  def update
    endorsement = ListingEndorsement.find(params[:id])

    authorize endorsement

    if endorsement.approved
      endorsement.update(approved: false)
    else
      endorsement.update(approved: true)
    end

    head :no_content
  end
end
