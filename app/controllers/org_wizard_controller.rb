class OrgWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!

  def show
    @new_org = params[:new_org].present?
    @organization_json = {
      name: @organization.name,
      slug: @organization.slug,
      bg_color_hex: @organization.bg_color_hex,
      has_page: @organization.readme_page?,
      new_org: @new_org
    }.to_json
  end

  def crawl
    urls = params[:urls].to_a.select(&:present?).first(4)
    page_type = params[:page_type].to_s.presence || "developer"
    crawler = Ai::OrgPageCrawler.new(organization: @organization, urls: urls, page_type: page_type)
    result = crawler.crawl
    render json: result
  end

  def generate
    org_data = params[:org_data]&.to_unsafe_h || {}
    dev_posts = params[:dev_posts]&.map(&:to_unsafe_h) || []

    generator = Ai::OrgPageGenerator.new(
      organization: @organization,
      org_data: org_data.deep_symbolize_keys,
      dev_posts: dev_posts.map(&:deep_symbolize_keys)
    )
    result = generator.generate
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def iterate
    org_data = params[:org_data]&.to_unsafe_h || {}
    dev_posts = params[:dev_posts]&.map(&:to_unsafe_h) || []

    generator = Ai::OrgPageGenerator.new(
      organization: @organization,
      org_data: org_data.deep_symbolize_keys,
      dev_posts: dev_posts.map(&:deep_symbolize_keys)
    )
    result = generator.iterate(
      current_markdown: params[:current_markdown].to_s,
      instruction: params[:instruction].to_s
    )
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def render_preview
    markdown = params[:markdown].to_s
    renderer = ContentRenderer.new(markdown, source: @organization, user: nil)
    result = renderer.process
    render json: { html: result.processed_html }
  rescue StandardError => e
    render json: { html: "<p class='color-accent-danger'>Render error: #{ERB::Util.html_escape(e.message)}</p>" }
  end

  def save
    markdown = params[:markdown].to_s
    detected_color = params[:detected_color]
    og_image = params[:og_image]
    urls = params[:urls].to_a.select(&:present?)

    updates = { page_markdown: markdown }
    updates[:bg_color_hex] = detected_color if detected_color.present? && detected_color.match?(Organization::COLOR_HEX_REGEXP)
    updates[:cover_image] = og_image if og_image.present? && og_image.start_with?("http") && @organization.cover_image.blank?
    updates.merge!(extract_profile_from_urls(urls))

    if @organization.update(updates)
      render json: { success: true, redirect_url: "/#{@organization.slug}" }
    else
      render json: { error: @organization.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:slug])
  end

  def authorize_admin!
    authorize @organization, :update?, policy_class: OrganizationPolicy
  end

  def extract_profile_from_urls(urls)
    updates = {}
    social = @organization.social_links || {}

    urls.each do |url|
      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError
        next
      end
      host = uri.host&.downcase&.sub(/\Awww\./, "") || next

      case host
      when /github\.com/
        username = uri.path.to_s.split("/").reject(&:blank?).first
        updates[:github_username] = username if username.present? && @organization.github_username.blank?
      when /youtube\.com/, /youtu\.be/
        social["youtube"] = url if social["youtube"].blank?
      when /twitter\.com/, /x\.com/
        username = uri.path.to_s.split("/").reject(&:blank?).first
        updates[:twitter_username] = username if username.present? && @organization.twitter_username.blank?
      when /linkedin\.com/
        social["linkedin"] = url if social["linkedin"].blank?
      when /discord\.(gg|com)/
        social["discord"] = url if social["discord"].blank?
      when /instagram\.com/
        social["instagram"] = url if social["instagram"].blank?
      when /facebook\.com/
        social["facebook"] = url if social["facebook"].blank?
      when /twitch\.tv/
        social["twitch"] = url if social["twitch"].blank?
      when /mastodon/
        social["mastodon"] = url if social["mastodon"].blank?
      when /spotify\.com/
        social["spotify"] = url if social["spotify"].blank?
      else
        # Use as website URL if it's a regular site and org has no URL set
        updates[:url] = url if @organization.url.blank? && !url.match?(/github|youtube|twitter|discord|linkedin|instagram|facebook/i)
      end
    end

    updates[:social_links] = social if social != (@organization.social_links || {})
    updates
  end
end
