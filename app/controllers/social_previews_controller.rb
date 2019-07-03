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
    cat_info = {
      "collabs": ["Collaborators Wanted", "#5AE8D9"],
      "cfp": ["Call For Proposal", "#f58f8d"],
      "forhire": ["Available For Hire", "#b78cf4"],
      "education": ["Education", "#5AABE8"],
      "jobs": ["Now Hiring", "#53c3ad"],
      "mentors": ["Offering Mentorship", "#A69EE8"],
      "mentees": ["Looking For Mentorship", "#88aedb"],
      "forsale": ["Stuff For Sale", "#d0adfb"],
      "events": ["Upcoming Event", "#f8b3d0"],
      "misc": ["Miscellaneous", "#6393FF"],
      "products": ["Products & Tools", "#5AE8D9"]
    }
    @category = cat_info[@listing.category.to_sym][0]
    @cat_color = cat_info[@listing.category.to_sym][1]
  end
end
