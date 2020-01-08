class CannedResponsesController < ApplicationController
  after_action :verify_authorized, except: %i[index]

  def index
    @canned_responses = if params[:type_of]
                          result = CannedResponse.where(user_id: nil, type_of: params[:type_of])
                          authorize result
                          result
                        else
                          skip_authorization
                          CannedResponse.where(user_id: current_user.id)
                        end
  end

  def create
    authorize CannedResponse
    @canned_response = CannedResponse.new(permitted_attributes(CannedResponse))
    @canned_response.user_id = current_user.id

    if @canned_response.save
      flash[:settings_notice] = "Your canned response \"#{@canned_response.title}\" was created."
    else
      flash[:error] = @canned_response.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: root_path)
  end

  def destroy
    @canned_response = CannedResponse.find(params[:id])
    authorize @canned_response

    if @canned_response.destroy
      flash[:settings_notice] = "Your canned response \"#{@canned_response.title}\" was deleted."
    else
      flash[:error] = @canned_response.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_back(fallback_location: root_path)
  end

  def update
    @canned_response = CannedResponse.find(params[:id])
    authorize @canned_response

    if @canned_response.update(permitted_attributes(CannedResponse))
      flash[:settings_notice] = "Your canned response \"#{@canned_response.title}\" was updated."
    else
      flash[:error] = @canned_response.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: root_path)
  end
end
