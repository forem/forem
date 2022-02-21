class ResponseTemplatesController < ApplicationController
  after_action :verify_authorized
  before_action :authenticate_user!, :ensure_json_request, only: %i[index]
  rescue_from ArgumentError, with: :error_unprocessable_entity

  MOD_TYPES = %w[mod_comment tag_adjustment].freeze
  ADMIN_TYPES = %w[email_reply abuse_report_email_reply].freeze

  def index
    raise ArgumentError, "Missing param type_of" if params[:type_of].blank?

    user_id = params[:type_of] == "personal_comment" ? current_user.id : nil
    @response_templates = ResponseTemplate.where(type_of: params[:type_of], user_id: user_id)

    if MOD_TYPES.include?(params[:type_of])
      authorize @response_templates, :moderator_index?
    elsif ADMIN_TYPES.include?(params[:type_of])
      authorize @response_templates, :admin_index?
    else
      authorize @response_templates, :index?
    end

    respond_to do |format|
      format.json { render :index }
    end
  end

  def create
    authorize ResponseTemplate
    response_template.user_id = current_user.id
    response_template.content_type = "body_markdown"
    response_template.type_of = "personal_comment"

    if response_template.save
      flash[:settings_notice] =
        I18n.t("response_templates_controller.created", title: response_template.title)
      redirect_to user_settings_path(tab: "response-templates", id: response_template.id)
    else
      flash[:error] =
        I18n.t("response_templates_controller.response_template_error", errors: response_template.errors_as_sentence)
      attributes = permitted_attributes(ResponseTemplate)
      redirect_to user_settings_path(
        tab: "response-templates",
        id: response_template.id,
        previous_title: attributes[:title],
        previous_content: attributes[:content],
      )
    end
  end

  def destroy
    authorize response_template

    if response_template.destroy
      flash[:settings_notice] =
        I18n.t("response_templates_controller.deleted", title: response_template.title)
    else
      flash[:error] = response_template.errors_as_sentence # this will probably never fail
    end

    redirect_to user_settings_path(tab: "response-templates")
  end

  def update
    authorize response_template

    attributes = permitted_attributes(ResponseTemplate)
    if response_template.update(attributes)
      flash[:settings_notice] =
        I18n.t("response_templates_controller.updated", title: response_template.title)
      redirect_to user_settings_path(tab: "response-templates", id: response_template.id)
    else
      flash[:error] =
        I18n.t("response_templates_controller.response_template_error", errors: response_template.errors_as_sentence)
      redirect_to user_settings_path(
        tab: "response-templates",
        id: response_template.id,
        previous_title: attributes[:title],
        previous_content: attributes[:content],
      )
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

  def ensure_json_request
    routing_error unless request.format == :json
  end

  def error_unprocessable_entity(message)
    render json: { error: message, status: 422 }, status: :unprocessable_entity
  end
end
