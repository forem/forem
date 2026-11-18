module Admin
  class EventPagesController < Admin::ApplicationController
    layout "admin"

    before_action :set_event
    before_action :set_page, only: %i[edit update destroy reorder toggle_showcase]
    before_action :validate_reorder_direction, only: :reorder

    SLUG_REQUIRED_MESSAGE = "suffix is required and must contain alphanumeric characters or hyphens".freeze

    def index
      @pages = @event.ordered_pages.to_a
      @showcase_page = @pages.detect(&:showcase?)
      @embed_pages = @event.ordered_embed_pages.to_a
    end

    def new
      template = params[:kind] == "embed" ? Page::EMBED_HTML_TEMPLATE : "full_within_layout"
      @page = @event.pages.build(template: template)
    end

    def edit; end

    def create
      if creating_embed_page?
        build_embed_page
      else
        build_markdown_page
      end
      return render :new, status: :unprocessable_entity if @page.errors.any?

      if save_event_page
        flash[:success] = I18n.t("views.admin.event_pages.created")
        redirect_to admin_event_pages_path(@event)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @page.embed_html?
        assign_embed_page_updates
      else
        assign_markdown_page_updates
      end
      return render :edit, status: :unprocessable_entity if @page.errors.any?

      if save_event_page
        Pages::BustCacheWorker.perform_async(@page.slug, nil, nil, @event.id)
        flash[:success] = I18n.t("views.admin.event_pages.updated")
        redirect_to admin_event_pages_path(@event)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @page.destroy!
      flash[:success] = I18n.t("views.admin.event_pages.deleted")
      redirect_to admin_event_pages_path(@event)
    end

    def reorder
      if reorder_page(params[:direction].to_s)
        Pages::BustCacheWorker.perform_async(@page.slug, nil, nil, @event.id)
        flash[:success] = I18n.t("views.admin.event_pages.reordered")
      end

      redirect_to admin_event_pages_path(@event)
    end

    def toggle_showcase
      if @page.embed_html?
        flash[:alert] = I18n.t("views.admin.event_pages.showcase_embed_forbidden")
      elsif @page.showcase?
        @page.assign_attributes(showcase: false)
        if save_event_page
          flash[:success] = I18n.t("views.admin.event_pages.showcase_unset")
        else
          flash[:alert] = @page.errors.full_messages.to_sentence
        end
      else
        @page.assign_attributes(showcase: true, show_in_navigation: true)
        if save_event_page
          flash[:success] = I18n.t("views.admin.event_pages.showcase_set")
        else
          flash[:alert] = @page.errors.full_messages.to_sentence
        end
      end

      redirect_to admin_event_pages_path(@event)
    end

    def preview
      if params.key?(:body_html)
        result = Pages::EmbedHtmlWrapper.preview_result(params[:body_html])
        render json: result[:json], status: result[:status]
        return
      end

      renderer = ContentRenderer.new(params[:body_markdown].to_s, source: @event.organization, user: current_user)
      result = renderer.process
      render json: { processed_html: result.processed_html }
    rescue ContentRenderer::ContentParsingError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    protected

    def authorization_resource
      Event
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    end

    def set_page
      @page = @event.pages.find(params[:id])
    end

    def save_event_page
      if @page.showcase? || @page.showcase_changed?
        @event.with_lock do
          sync_page_slug_with_committed_event
          @page.save
        end
      elsif @page.new_record? || @page.slug_changed?
        Page.transaction do
          @event.reload(lock: "FOR SHARE")
          sync_page_slug_with_committed_event
          @page.save
        end
      else
        @page.save
      end
    end

    def sync_page_slug_with_committed_event
      return if @page.slug.blank?

      suffix = @page.slug.split("/").last
      return if suffix.blank?

      @page.slug = if @page.embed_html?
                     @event.embed_page_slug_for(suffix)
                   else
                     @event.page_slug_for(suffix)
                   end
      @page.association(:event).target = @event
    end

    def creating_embed_page?
      params[:kind] == "embed" || params.dig(:page, :template) == Page::EMBED_HTML_TEMPLATE
    end

    def build_embed_page
      @page = @event.pages.build(embed_page_params)
      @page.template = Page::EMBED_HTML_TEMPLATE
      @page.position = 0
      @page.showcase = false
      @page.description = default_page_description if @page.description.blank?

      suffix = normalized_slug_suffix
      if suffix.blank?
        @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
        return
      end

      @page.slug = @event.embed_page_slug_for(suffix)
    end

    def build_markdown_page
      @page = @event.pages.build(markdown_page_params)
      @page.template = "full_within_layout"
      @page.position = (@event.ordered_pages.maximum(:position) || -1) + 1
      @page.description = default_page_description if @page.description.blank?

      suffix = normalized_slug_suffix
      suffix = "readme" if suffix.blank? && @page.showcase?
      if suffix.blank?
        @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
        return
      end

      @page.slug = @event.page_slug_for(suffix)
    end

    def assign_embed_page_updates
      @page.assign_attributes(embed_page_params)
      @page.description = default_page_description if @page.description.blank?
      suffix = normalized_slug_suffix
      if suffix.blank?
        @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
        return
      end

      @page.slug = @event.embed_page_slug_for(suffix)
    end

    def assign_markdown_page_updates
      @page.assign_attributes(markdown_page_params)
      @page.description = default_page_description if @page.description.blank?
      suffix = normalized_slug_suffix
      suffix = "readme" if suffix.blank? && @page.showcase?
      if suffix.blank?
        @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
        return
      end

      @page.slug = @event.page_slug_for(suffix)
    end

    def default_page_description
      @event.description.presence || @event.title
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
      params.require(:page).permit(:title, :body_markdown, :description, :show_in_navigation, :showcase)
    end

    def embed_page_params
      params.require(:page).permit(:title, :body_html, :description)
    end

    def reorder_page(direction)
      return false if @page.showcase? || @page.embed_html?

      Page.transaction do
        pages = ordered_reorderable_pages
        current_index = pages.index { |page| page.id == @page.id }
        adjacent_index = adjacent_index_for(current_index, direction)
        next false unless adjacent_index&.between?(0, pages.length - 1)

        normalize_positions(pages)
        swap_positions(pages, current_index, adjacent_index)
        true
      end
    end

    def ordered_reorderable_pages
      @event.ordered_pages.where(showcase: false).lock.to_a
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
      page.update_columns(position: position, updated_at: Time.current)
    end

    def validate_reorder_direction
      head :unprocessable_entity unless %w[up down].include?(params[:direction].to_s)
    end
  end
end
