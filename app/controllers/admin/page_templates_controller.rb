module Admin
  class PageTemplatesController < Admin::ApplicationController
    layout "admin"

    PAGE_TEMPLATE_ALLOWED_PARAMS = %i[
      name description body_html body_markdown template_type
    ].freeze

    def index
      @page_templates = PageTemplate.includes(:forked_from, :forks).order(created_at: :desc)
    end

    def show
      @page_template = PageTemplate.find(params[:id])
      @pages = @page_template.pages.order(created_at: :desc)
    end

    def new
      if params[:fork_from]
        original = PageTemplate.find(params[:fork_from])
        @page_template = original.fork(new_name: "#{original.name} (Fork)")
      else
        @page_template = PageTemplate.new(
          data_schema: { "fields" => [] },
        )
      end
    end

    def edit
      @page_template = PageTemplate.find(params[:id])
    end

    def create
      @page_template = PageTemplate.new(page_template_params)
      @page_template.data_schema = parse_data_schema

      if @page_template.save
        flash[:success] = I18n.t("admin.page_templates_controller.created")
        redirect_to admin_page_templates_path
      else
        flash.now[:error] = @page_template.errors_as_sentence
        render :new
      end
    end

    def update
      @page_template = PageTemplate.find(params[:id])

      if @page_template.update(page_template_params)
        flash[:success] = I18n.t("admin.page_templates_controller.updated")
        redirect_to admin_page_templates_path
      else
        flash.now[:error] = @page_template.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @page_template = PageTemplate.find(params[:id])

      if @page_template.pages.exists?
        flash[:error] = I18n.t("admin.page_templates_controller.cannot_delete_with_pages")
        redirect_to admin_page_templates_path
      else
        @page_template.destroy
        flash[:success] = I18n.t("admin.page_templates_controller.deleted")
        redirect_to admin_page_templates_path
      end
    end

    private

    def page_template_params
      params.require(:page_template).permit(PAGE_TEMPLATE_ALLOWED_PARAMS)
    end

    def parse_data_schema
      field_names = params.dig(:page_template, :field_names) || []
      field_types = params.dig(:page_template, :field_types) || []
      field_labels = params.dig(:page_template, :field_labels) || []
      field_required = params.dig(:page_template, :field_required) || []

      fields = field_names.each_with_index.filter_map do |name, index|
        next if name.blank?

        {
          "name" => name.parameterize.underscore,
          "type" => field_types[index] || "text",
          "label" => field_labels[index].presence || name.titleize,
          "required" => field_required[index] == "1",
        }
      end

      { "fields" => fields }
    end
  end
end

