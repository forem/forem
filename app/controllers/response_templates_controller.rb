class ResponseTemplatesController < ApplicationController
  after_action :verify_authorized
  before_action :authenticate_user!, :ensure_json_request, only: %i[index]
  rescue_from ArgumentError, with: :error_unprocessable_entity

  MOD_TYPES = %w[mod_comment tag_adjustment].freeze
  ADMIN_TYPES = %w[email_reply abuse_report_email_reply].freeze

  # This endpoint is called to provide a mix of personal & mod_comment templates
  # when replying to a comment, it also might be called for Email and Abuse
  # Report Email templates. To be compatible with both uses, it returns a Hash
  # sometimes and an array at other times. When type_of is present, this returns
  # an array of templates. When the type_of param is missing, this returns a
  # hash, keys are type_ofs, values are an array of templates.
  def index
    @response_templates = policy_scope(ResponseTemplate).group_by(&:type_of)
    @response_templates = @response_templates.fetch(params[:type_of], []) if params[:type_of].present?

    if MOD_TYPES.include?(params[:type_of])
      authorize :response_template, :moderator_index?
    elsif ADMIN_TYPES.include?(params[:type_of])
      authorize :response_template, :admin_index?
    else
      authorize :response_template, :index?
    end

    respond_to do |format|
      format.json { render :index }
    end
  end

  def create
    authorize ResponseTemplate

    unless tries_to_create_a_mod_response_template? && can_create_mod_response_templates?
      response_template.user_id = current_user.id
      response_template.type_of = "personal_comment"
    end
    response_template.content_type = "body_markdown"

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

  private

  def authorized_user
    @authorized_user ||= Authorizer.for(user: current_user)
  end

  def can_create_mod_response_templates?
    authorized_user.accesses_mod_response_templates?
  end

  def tries_to_create_a_mod_response_template?
    params[:response_template][:type_of] == "mod_comment"
  end

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
