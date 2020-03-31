class SocialPreviewsController < ApplicationController
  # No authorization required for entirely public controller

  PNG_CSS = "body { transform: scale(0.3); } .preview-div-wrapper { overflow: unset; margin: 5vw; }".freeze

  def article
    @article = Article.find(params[:id])
    @tag_badges = Badge.where(id: Tag.where(name: @article.decorate.cached_tag_list_array).pluck(:badge_id))
    not_found unless @article.published

    template = @article.tags.
      where("tags.social_preview_template IS NOT NULL AND tags.social_preview_template != ?", "article").
      select(:social_preview_template).first&.social_preview_template

    # make sure that the template exists
    template = "article" unless Tag.social_preview_templates.include?(template)

    set_respond "social_previews/articles/#{template}"
  end

  def user
    @user = User.find(params[:id])
    @tag_badges = Badge.where(id: @user.badge_achievements.pluck(:badge_id))
    set_respond
  end

  def listing
    @listing = ClassifiedListing.find(params[:id])
    define_categories
    set_respond
  end

  def organization
    @user = Organization.find(params[:id])
    @tag_badges = [] # Orgs don't have badges, but they could!
    set_respond "user"
  end

  def tag
    @tag = Tag.find(params[:id])

    set_respond
  end

  def comment
    @comment = Comment.find(params[:id])
    @tag_badges = Badge.where(id: Tag.where(name: @comment.commentable&.decorate&.cached_tag_list_array).pluck(:badge_id))

    set_respond
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

  def set_respond(template = nil)
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
end
