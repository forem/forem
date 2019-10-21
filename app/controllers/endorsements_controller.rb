class EndorsementsController < ApplicationController
  before_action :set_endorsement, only: %i[update destroy]
  before_action :authenticate_user!, only: %i[create update destroy]
  after_action :verify_authorized

  # POST /endorsements.json
  def create
    authorize Endorsement
    @endorsement = Endorsement.new(endorsement_params.merge(user_id: current_user.id, deleted: false, edited: false, approved: true))

    respond_to do |format|
      if @endorsement.save
        @endorsement.classified_listing.index!
        format.json { render :show, status: :created, location: @endorsement }
      else
        format.json { render json: @endorsement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /endorsements/1.json
  def update
    authorize @endorsement
    respond_to do |format|
      if @endorsement.update(endorsement_params.merge(edited: true))
        @endorsement.classified_listing.index!
        format.json { render :show, status: :ok, location: @endorsement }
      else
        format.json { render json: @endorsement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /endorsements/1.json
  def destroy
    authorize @endorsement
    @endorsement.update(deleted: true)
    @endorsement.classified_listing.index!

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_endorsement
    @endorsement = Endorsement.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def endorsement_params
    params.permit(policy(Endorsement).permitted_attributes)
  end
end
