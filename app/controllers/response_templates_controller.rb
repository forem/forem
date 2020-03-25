class ResponseTemplatesController < ApplicationController
  after_action :verify_authorized

  def create
    authorize ResponseTemplate
    @response_template = ResponseTemplate.new(permitted_attributes(ResponseTemplate))
    @response_template.user_id = current_user.id
    @response_template.content_type = "body_markdown"
    @response_template.type_of = "personal_comment"

    if @response_template.save
      flash[:settings_notice] = "Your response template \"#{@response_template.title}\" was created."
    else
      flash[:error] = "Response template error: #{@response_template.errors.full_messages.to_sentence}"
    end

    redirect_to user_settings_path(tab: "response-templates", id: @response_template.id)
  end

  def destroy
    @response_template = ResponseTemplate.find(params[:id])
    authorize @response_template

    if @response_template.destroy
      flash[:settings_notice] = "Your response template \"#{@response_template.title}\" was deleted."
    else
      flash[:error] = @response_template.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_to user_settings_path(tab: "response-templates")
  end

  def update
    @response_template = ResponseTemplate.find(params[:id])
    authorize @response_template

    if @response_template.update(permitted_attributes(ResponseTemplate))
      flash[:settings_notice] = "Your response template \"#{@response_template.title}\" was updated."
    else
      flash[:error] = "Response template error: #{@response_template.errors.full_messages.to_sentence}"
    end
    redirect_to user_settings_path(tab: "response-templates", id: @response_template.id, previous_content: permitted_attributes(ResponseTemplate)[:content])
  end

  private

  def handle_authorization(records)
    case params[:type_of]
    when "mod_comment"
      authorize records, :moderator_index?
    else
      authorize records, :admin_index?
    end
  end
end
