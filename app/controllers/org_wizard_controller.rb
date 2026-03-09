class OrgWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!

  def show
    @organization_json = {
      name: @organization.name,
      slug: @organization.slug,
      bg_color_hex: @organization.bg_color_hex,
      has_page: @organization.readme_page?
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

  def save
    markdown = params[:markdown].to_s
    detected_color = params[:detected_color]

    updates = { page_markdown: markdown }
    updates[:bg_color_hex] = detected_color if detected_color.present? && detected_color.match?(/\A#[0-9A-Fa-f]{6}\z/)

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
end
