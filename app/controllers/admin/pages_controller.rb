module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    PAGE_ALLOWED_PARAMS = %i[
      title slug body_markdown body_html body_json body_css description template
      is_top_level_path social_image landing_page page_template_id
    ].freeze

    def index
      @pages = Page.from_subforem.includes(:page_template).order(created_at: :desc)
      @code_of_conduct = Page.find_by(slug: Page::CODE_OF_CONDUCT_SLUG)
      @privacy = Page.find_by(slug: Page::PRIVACY_SLUG)
      @terms = Page.find_by(slug: Page::TERMS_SLUG)
      @page_templates = PageTemplate.order(:name)
    end

    def new
      @landing_page = Page.landing_page
      @page_templates = PageTemplate.order(:name)

      if (page_template_id = params[:page_template_id])
        @page_template = PageTemplate.find_by(id: page_template_id)
        @page = Page.new(page_template: @page_template)
      elsif (slug = params[:slug])
        prepopulate_new_form(slug)
      elsif params[:page]
        original_page = Page.find_by(id: params[:page])
        if original_page
          @page = original_page.dup
          # If forking a template-based page, preserve the template relationship
          if original_page.page_template.present?
            @page_template = original_page.page_template
            @page.page_template = @page_template
            @page.template_data = original_page.template_data&.dup || {}
          end
        else
          @page = Page.new
        end
      else
        @page = Page.new
      end
    end

    def edit
      @page = Page.find(params[:id])
      @landing_page = Page.landing_page
      @page_templates = PageTemplate.order(:name)
      @page_template = @page.page_template
    end

    def create
      @page = Page.new(page_params)
      @page.template_data = parse_template_data if @page.page_template_id.present?

      if @page.save
        flash[:success] = I18n.t("admin.pages_controller.created")
        redirect_to admin_pages_path
      else
        @page_templates = PageTemplate.order(:name)
        @page_template = @page.page_template
        flash.now[:error] = @page.errors_as_sentence
        render :new
      end
    end

    def update
      @page = Page.find(params[:id])
      @page.assign_attributes(page_params)
      @page.template_data = parse_template_data if @page.page_template_id.present?

      if @page.save
        flash[:success] = I18n.t("admin.pages_controller.updated")
        redirect_to admin_pages_path
      else
        @page_templates = PageTemplate.order(:name)
        @page_template = @page.page_template
        flash.now[:error] = @page.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy
      flash[:success] = I18n.t("admin.pages_controller.deleted")
      redirect_to admin_pages_path
    end

    private

    def page_params
      params.require(:page).permit(PAGE_ALLOWED_PARAMS)
    end

    def parse_template_data
      template_data = params.dig(:page, :template_data)
      return {} if template_data.blank?

      template_data.permit!.to_h
    end

    def prepopulate_new_form(slug)
      html = view_context.render partial: "pages/coc_text",
                                 locals: {
                                   community_name: view_context.community_name,
                                   contact_link: view_context.contact_link
                                 }
      @page = case slug
              when Page::CODE_OF_CONDUCT_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: I18n.t("admin.pages_controller.code_of_conduct.title"),
                  description: I18n.t("admin.pages_controller.code_of_conduct.description"),
                  is_top_level_path: true,
                )
              when Page::PRIVACY_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: I18n.t("admin.pages_controller.privacy_policy.title"),
                  description: I18n.t("admin.pages_controller.privacy_policy.description"),
                  is_top_level_path: true,
                )
              when Page::TERMS_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: I18n.t("admin.pages_controller.terms_of_use.title"),
                  description: I18n.t("admin.pages_controller.terms_of_use.description"),
                  is_top_level_path: true,
                )
              else
                Page.new
              end
    end
  end
end
