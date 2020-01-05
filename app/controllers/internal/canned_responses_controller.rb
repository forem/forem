class Internal::CannedResponsesController < Internal::ApplicationController
  layout "internal"

  def index
    @canned_responses = if params[:filter]
                          CannedResponse.where(type_of: params[:filter])
                        else
                          CannedResponse.all
                        end
    @canned_responses = @canned_responses.page(params[:page]).per(50)
  end

  def create
    @canned_response = CannedResponse.new(permitted_params)
    if @canned_response.save
      flash[:success] = "Canned response: \"#{@canned_response.title}\" saved successfully."
      redirect_to("/internal/canned_responses/#{@canned_response.id}/edit")
    else
      flash[:danger] = @canned_response.errors.full_messages.to_sentence
      @canned_responses = CannedResponse.all.page(params[:page]).per(50)
      render :index
    end
  end

  def edit
    @canned_response = CannedResponse.find(params[:id])
  end

  def update
    @canned_response = CannedResponse.find(params[:id])

    if @canned_response.update(permitted_attributes(CannedResponse))
      flash[:success] = "The canned response \"#{@canned_response.title}\" was updated."
    else
      flash[:danger] = @canned_response.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: "/internal/canned_responses/#{@canned_response.id}")
  end

  def destroy
    @canned_response = CannedResponse.find(params[:id])

    if @canned_response.destroy
      flash[:success] = "The canned response \"#{@canned_response.title}\" was deleted."
    else
      flash[:danger] = @canned_response.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_to "/internal/canned_responses"
  end

  private

  def permitted_params
    params.require(:canned_response).permit(:body_markdown, :user_id, :content, :title, :type_of, :content_type)
  end
end
