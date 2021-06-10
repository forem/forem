module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    def index
      @pages = Page.all.order(created_at: :desc)
      @code_of_conduct = Page.find_by(slug: "code-of-conduct")
      @privacy = Page.find_by(slug: "privacy")
      @terms = Page.find_by(slug: "terms")
    end

    def new
      @landing_page = Page.find_by(landing_page: true)
      if (slug = params[:slug])
        prepopulate_new_form(slug)
      else
        @page = Page.new
      end
    end

    def edit
      @page = Page.find(params[:id])
      @landing_page = Page.find_by(landing_page: true)
    end

    def update
      @page = Page.find(params[:id])
      if update_and_overwrite_landing_page
        flash[:success] = "Page has been successfully updated."
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :edit
      end
    end

    def create
      @page = Page.new(page_params)
      if create_and_overwrite_landing_page
        flash[:success] = "Page has been successfully created."
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :new
      end
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy
      flash[:success] = "Page has been successfully deleted."
      redirect_to admin_pages_path
    end

    private

    def page_params
      allowed_params = %i[title slug body_markdown body_html body_json description template is_top_level_path
                          social_image landing_page overwrite_landing_page]
      params.require(:page).permit(allowed_params)
    end

    def prepopulate_new_form(slug)
      html = view_context.render partial: "pages/coc_text",
                                 locals: {
                                   community_name: view_context.community_name,
                                   email_link: view_context.email_link
                                 }
      @page = case slug
              when "code-of-conduct"
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Code of Conduct",
                  description: "A page that describes how to behave on this platform",
                  is_top_level_path: true,
                )
              when "privacy"
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Privacy Policy",
                  description: "A page that describes the privacy policy",
                  is_top_level_path: true,
                )
              when "terms"
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Terms of Use",
                  description: "A page that describes the terms of use for the application",
                  is_top_level_path: true,
                )
              else
                Page.new
              end
    end

    def update_and_overwrite_landing_page
      if page_params["overwrite_landing_page"] == "true"
        Page.transaction do
          current_landing_page = Page.find_by(landing_page: true)
          current_landing_page&.update(landing_page: false)

          @page.update(page_params)
        end
      else
        @page.update(page_params)
      end
    end

    def create_and_overwrite_landing_page
      if page_params["overwrite_landing_page"] == "true"
        Page.transaction do
          current_landing_page = Page.find_by(landing_page: true)
          current_landing_page&.update(landing_page: false)

          @page.save
        end
      else
        @page.save
      end
    end
  end
end
