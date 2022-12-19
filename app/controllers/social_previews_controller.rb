class SocialPreviewsController < ApplicationController
  # No authorization required for entirely public controller

  PNG_CSS = "body { transform: scale(0.3); } .preview-div-wrapper { overflow: unset; margin: 5vw; }".freeze

  def article
    @article = Article.find(params[:id])
    @tag_badges = Badge.where(id: Tag.where(name: @article.decorate.cached_tag_list_array).select(:badge_id))
    not_found unless @article.published

    template = @article.tags
      .where.not(social_preview_template: nil)
      .where.not(social_preview_template: "article")
      .select(:social_preview_template).first&.social_preview_template

    # make sure that the template exists
    template = "article" unless Tag.social_preview_templates.include?(template)

    set_respond "social_previews/articles/#{template}"
  end

  private

  def set_respond(template = nil)
    respond_to do |format|
      format.html do
        render template, layout: false
      end
      format.png do
        html = render_to_string(template, formats: :html, layout: false)
        url = HtmlCssToImage.fetch_url(html: html, css: PNG_CSS,
                                       google_fonts: I18n.t("social_previews_controller.fonts"))
        redirect_to url, allow_other_host: true, status: :found
      end
    end
  end
end
