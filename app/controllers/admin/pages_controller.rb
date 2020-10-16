module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    def index
      @pages = Page.all
      @code_of_conduct = Page.find_by(slug: "code-of-conduct")
      @privacy = Page.find_by(slug: "privacy")
      @terms = Page.find_by(slug: "terms")
    end

    def new
      if params[:slug]
        prepopulate_new_form params[:slug]
      else
        @page = Page.new
      end
    end

    def edit
      @page = Page.find(params[:id])
    end

    def update
      @page = Page.find(params[:id])
      @page.update!(page_params)
      redirect_to "/admin/pages"
    end

    def create
      @page = Page.new(page_params)
      @page.save!
      redirect_to "/admin/pages"
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy
      redirect_to "/admin/pages"
    end

    private

    def page_params
      allowed_params = %i[title slug body_markdown body_html body_json description template is_top_level_path
                          social_image]
      params.require(:page).permit(allowed_params)
    end

    def prepopulate_new_form(slug)
      if slug == "code-of-conduct"
        html = view_context.render partial: "pages/coc_text",
                                   locals: {
                                     community_name: view_context.community_name,
                                     community_qualified_name: view_context.community_qualified_name,
                                     email_link: view_context.email_link
                                   }
        @page = Page.new(
          slug: params[:slug],
          body_html: html,
          title: "Code of Conduct",
          description: "A page that describes how to behave on this platform",
          is_top_level_path: true,
        )
      elsif slug == "privacy"
        html = view_context.render partial: "pages/privacy_text",
                                   locals: {
                                     community_name: view_context.community_name,
                                     email_link: view_context.email_link
                                   }
        @page = Page.new(
          slug: params[:slug],
          body_html: html,
          title: "Privacy Policy",
          description: "A page that describes the privacy policy",
          is_top_level_path: true,
        )
      elsif slug == "terms"
        html = view_context.render partial: "pages/terms_text",
                                   locals: {
                                     community_name: view_context.community_name,
                                     email_link: view_context.email_link
                                   }
        @page = Page.new(
          slug: params[:slug],
          body_html: html,
          title: "Terms of Use",
          description: "A page that describes the terms of use for the application",
          is_top_level_path: true,
        )
      else
        @page = Page.new
      end
    end
  end
end
