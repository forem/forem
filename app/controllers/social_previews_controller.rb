class SocialPreviewsController < ApplicationController
  # No authorization required for entirely public controller

  PNG_CSS = "body { transform: scale(0.3); } .preview-div-wrapper { overflow: unset; margin: 5vw; }".freeze
  SHE_CODED_TAGS = %w[shecoded theycoded shecodedally].freeze

  def article
    @article = Article.find(params[:id])
    not_found unless @article.published

    template = (@article.decorate.cached_tag_list_array & SHE_CODED_TAGS).any? ? "shecoded" : "article"

    respond_to do |format|
      format.html do
        render template, layout: false
      end
      format.png do
        html = render_to_string(template, formats: :html, layout: false)
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto|Roboto+Condensed"), status: 302
      end
    end
  end

  def user
    @user = User.find(params[:id]) || not_found

    respond_to do |format|
      format.html do
        render layout: false
      end
      format.png do
        html = render_to_string(formats: :html, layout: false)
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto"), status: 302
      end
    end
  end

  def organization
    @user = Organization.find(params[:id]) || not_found

    respond_to do |format|
      format.html do
        render "user", layout: false
      end
      format.png do
        html = render_to_string("user", formats: :html, layout: false)
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto"), status: 302
      end
    end
  end

  def tag
    @tag = Tag.find(params[:id]) || not_found

    respond_to do |format|
      format.html do
        render layout: false
      end
      format.png do
        html = render_to_string(formats: :html, layout: false)
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto"), status: 302
      end
    end
  end
end
