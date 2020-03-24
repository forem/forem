class ResponseTemplatesController < ApplicationController
  after_action :verify_authorized, except: %i[index]

  def index
    not_found unless current_user
    @response_templates = if params[:type_of] && params[:personal_included] != "true"
                            result = ResponseTemplate.where(user_id: nil, type_of: params[:type_of])
                            handle_authorization(result)
                            result
                          elsif params[:type_of] == "mod_comment" && params[:personal_included] == "true"
                            result = ResponseTemplate.
                              where(user_id: nil, type_of: "mod_comment").
                              union(user_id: current_user.id, type_of: "personal_comment")
                            handle_authorization(result)
                            result
                          else
                            skip_authorization
                            ResponseTemplate.where(user_id: current_user.id)
                          end
  end

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

    redirect_back(fallback_location: user_settings_path)
  end

  def destroy
    @response_template = ResponseTemplate.find(params[:id])
    authorize @response_template

    if @response_template.destroy
      flash[:settings_notice] = "Your response template \"#{@response_template.title}\" was deleted."
    else
      flash[:error] = @response_template.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_back(fallback_location: user_settings_path)
  end

  def update
    @response_template = ResponseTemplate.find(params[:id])
    authorize @response_template

    if @response_template.update(permitted_attributes(ResponseTemplate))
      flash[:settings_notice] = "Your response template \"#{@response_template.title}\" was updated."
    else
      flash[:error] = "Response template error: #{@response_template.errors.full_messages.to_sentence}"
    end

    redirect_back(fallback_location: user_settings_path)
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
