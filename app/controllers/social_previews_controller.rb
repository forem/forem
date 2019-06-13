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
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto|Roboto+Condensed"), status: :found
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
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto|Roboto+Condensed"), status: :found
      end
    end
  end

  def listing
    @listing = ClassifiedListing.find(params[:id]) || not_found
    define_categories
    respond_to do |format|
      format.html do
        render layout: false
      end
      format.png do
        html = render_to_string(formats: :html, layout: false)
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto|Roboto+Condensed"), status: :found
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
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto"), status: :found
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
        redirect_to HtmlCssToImage.fetch_url(html: html, css: PNG_CSS, google_fonts: "Roboto"), status: :found
      end
    end
  end

  private

  def define_categories
    case @listing.category
    when "collabs"
      @category = "Collaborators Wanted"
      @cat_color = "#5AE8D9"
    when "cfp"
      @category = "Call For Proposal"
      @cat_color = "#f58f8d"
    when "forhire"
      @category = "Available For Hire"
      @cat_color = "#b78cf4"
    when "education"
      @category = "Education"
      @cat_color = "#5AABE8"
    when "jobs"
      @category = "Now Hiring"
      @cat_color = "#53c3ad"
    when "mentors"
      @category = "Offering Mentorship"
      @cat_color = "#A69EE8"
    when "mentees"
      @category = "Looking For Mentorship"
      @cat_color = "#88aedb"
    when "forsale"
      @category = "Stuff For Sale"
      @cat_color = "#d0adfb"
    when "events"
      @category = "Upcoming Event"
      @cat_color = "#f8b3d0"
    when "misc"
      @category = "Miscellaneous"
      @cat_color = "#6393FF"
    when "products"
      @category = "Products & Tools"
      @cat_color = "#5AE8D9"
    end
  end
end
