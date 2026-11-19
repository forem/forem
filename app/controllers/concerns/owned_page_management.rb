module OwnedPageManagement
  extend ActiveSupport::Concern

  SLUG_REQUIRED_MESSAGE = "suffix is required and must contain alphanumeric characters or hyphens".freeze

  private

  def creating_embed_page?
    params[:kind] == "embed" || params.dig(:page, :template) == Page::EMBED_HTML_TEMPLATE
  end

  def normalized_slug_suffix
    params.dig(:page, :slug_suffix)
      .to_s
      .strip
      .downcase
      .gsub(/[^a-z0-9\-]/, "-")
      .squeeze("-")
      .gsub(/\A-+|-+\z/, "")
  end

  def markdown_page_params
    params.require(:page).permit(:title, :body_markdown, :description, :show_in_navigation)
  end

  def embed_page_params
    params.require(:page).permit(:title, :body_html, :description)
  end

  def render_page_preview(source:)
    if params.key?(:body_html)
      result = Pages::EmbedHtmlWrapper.preview_result(params[:body_html])
      render json: result[:json], status: result[:status]
      return
    end

    renderer = ContentRenderer.new(params[:body_markdown].to_s, source: source, user: current_user)
    result = renderer.process
    render json: { processed_html: result.processed_html }
  rescue ContentRenderer::ContentParsingError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def reorder_page(direction)
    return false if showcase_page?(@page) || @page.embed_html?

    Page.transaction do
      pages = ordered_custom_pages
      current_index = pages.index { |page| page.id == @page.id }
      adjacent_index = adjacent_index_for(current_index, direction)
      next false unless adjacent_index&.between?(0, pages.length - 1)

      normalize_positions(pages)
      swap_positions(pages, current_index, adjacent_index)
      true
    end
  end

  def adjacent_index_for(current_index, direction)
    current_index && (current_index + (direction == "up" ? -1 : 1))
  end

  def normalize_positions(pages)
    pages.each_with_index do |page, index|
      update_position(page, index + 1) unless page.position == index + 1
    end
  end

  def swap_positions(pages, current_index, adjacent_index)
    update_position(pages.fetch(current_index), adjacent_index + 1)
    update_position(pages.fetch(adjacent_index), current_index + 1)
  end

  def update_position(page, position)
    # Ordering does not affect page validity or rendered Markdown, so avoid recompiling page content.
    page.update_columns(position: position, updated_at: Time.current)
  end

  def validate_reorder_direction
    head :unprocessable_entity unless %w[up down].include?(params[:direction].to_s)
  end
end
