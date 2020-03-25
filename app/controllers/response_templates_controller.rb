class ResponseTemplatesController < ApplicationController
  after_action :verify_authorized

  def create
    authorize ResponseTemplate
    response_template.user_id = current_user.id
    response_template.content_type = "body_markdown"
    response_template.type_of = "personal_comment"

    if response_template.save
      flash[:settings_notice] = "Your response template \"#{response_template.title}\" was created."
    else
      flash[:error] = "Response template error: #{response_template.errors.full_messages.to_sentence}"
      previous_title = permitted_attributes(ResponseTemplate)[:title]
      previous_content = permitted_attributes(ResponseTemplate)[:content]
    end

    redirect_to user_settings_path(
      tab: "response-templates",
      id: response_template.id,
      previous_title: previous_title,
      previous_content: previous_content
    )
  end

  def destroy
    authorize response_template

    if response_template.destroy
      flash[:settings_notice] = "Your response template \"#{response_template.title}\" was deleted."
    else
      flash[:error] = response_template.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_to user_settings_path(tab: "response-templates")
  end

  def update
    authorize response_template

    if response_template.update(permitted_attributes(ResponseTemplate))
      flash[:settings_notice] = "Your response template \"#{response_template.title}\" was updated."
      redirect_to user_settings_path(tab: "response-templates", id: response_template.id)
    else
      flash[:error] = "Response template error: #{response_template.errors.full_messages.to_sentence}"
      redirect_to user_settings_path(
        tab: "response-templates",
        id: response_template.id,
        previous_title: permitted_attributes(ResponseTemplate)[:title],
        previous_content: permitted_attributes(ResponseTemplate)[:content])
    end
  end

  private

  def response_template
    @response_template ||= if params[:id].present?
      ResponseTemplate.find(params[:id])
    else
      ResponseTemplate.new(permitted_attributes(ResponseTemplate))
    end
  end
end
