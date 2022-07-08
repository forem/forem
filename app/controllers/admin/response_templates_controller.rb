module Admin
  class ResponseTemplatesController < Admin::ApplicationController
    layout "admin"
    after_action only: %i[create update destroy] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @response_templates = if params[:filter]
                              ResponseTemplate.where(type_of: params[:filter])
                            else
                              ResponseTemplate.all
                            end
      @response_templates = @response_templates.page(params[:page]).per(50)
    end

    def new
      @response_template = ResponseTemplate.new
    end

    def create
      @response_template = ResponseTemplate.new(permitted_params)
      @response_template.user = find_user_via_identifier params[:response_template][:user_identifier]
      if @response_template.save
        flash[:success] =
          I18n.t("admin.response_templates_controller.saved",
                 title: @response_template.title)
        redirect_to admin_response_templates_path
      else
        flash[:danger] = @response_template.errors_as_sentence
        @response_templates = ResponseTemplate.page(params[:page]).per(50)
        render :new
      end
    end

    def edit
      @response_template = ResponseTemplate.find(params[:id])
    end

    def update
      @response_template = ResponseTemplate.find(params[:id])
      @response_template.user = find_user_via_identifier params[:response_template][:user_identifier]

      if @response_template.update(permitted_attributes(ResponseTemplate))
        flash[:success] =
          I18n.t("admin.response_templates_controller.updated",
                 title: @response_template.title)
        redirect_to edit_admin_response_template_path(@response_template)
      else
        flash[:danger] = @response_template.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @response_template = ResponseTemplate.find(params[:id])

      if @response_template.destroy
        flash[:success] =
          I18n.t("admin.response_templates_controller.deleted",
                 title: @response_template.title)
      else
        flash[:danger] = @response_template.errors_as_sentence # this will probably never fail
      end

      redirect_back(fallback_location: admin_response_templates_path)
    end

    private

    def find_user_via_identifier(identifier)
      return if identifier.blank?

      UsersQuery.find identifier
    end

    def permitted_params
      params.require(:response_template).permit(:body_markdown, :user_id, :content, :title, :type_of, :content_type)
    end
  end
end
