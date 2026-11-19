module Admin
  class EventPagesController < Admin::ApplicationController
    include OwnedPageManagement

    layout "admin"

    before_action :set_event
    before_action :set_page, only: %i[edit update destroy reorder]
    before_action :validate_reorder_direction, only: :reorder

    def index
      @pages = @event.ordered_pages.to_a
      @showcase_page = @pages.detect(&:event_showcase?)
      @embed_pages = @event.ordered_embed_pages.to_a
    end

    def new
      @page = if params[:kind] == "embed"
                @event.pages.build(template: Page::EMBED_HTML_TEMPLATE)
              elsif params[:kind] == "showcase"
                @event.pages.build(
                  template: "full_within_layout",
                  slug: @event.page_slug_for(Page::SHOWCASE_SLUG_SUFFIX),
                  title: I18n.t("views.events.pages.tabs.showcase"),
                )
              else
                @event.pages.build(template: "full_within_layout")
              end
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

    def preview
      render_page_preview(source: @event.organization)
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
      return @page.save unless @page.new_record? || @page.slug_changed?

      Page.transaction do
        @event.reload(lock: "FOR SHARE")
        sync_page_slug_with_committed_event
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

    def creating_showcase_page?
      params[:kind] == "showcase" || normalized_slug_suffix == Page::SHOWCASE_SLUG_SUFFIX
    end

    def build_embed_page
      @page = @event.pages.build(embed_page_params)
      @page.template = Page::EMBED_HTML_TEMPLATE
      @page.position = 0
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
      @page.description = default_page_description if @page.description.blank?

      if creating_showcase_page?
        @page.slug = @event.page_slug_for(Page::SHOWCASE_SLUG_SUFFIX)
        @page.position = 0
        @page.show_in_navigation = true
        @page.title = I18n.t("views.events.pages.tabs.showcase") if @page.title.blank?
      else
        suffix = normalized_slug_suffix
        if suffix.blank?
          @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
          return
        end

        @page.slug = @event.page_slug_for(suffix)
        @page.position = [(@event.ordered_pages.maximum(:position) || 0) + 1, 1].max
      end
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
      if @page.event_showcase?
        @page.slug = @event.page_slug_for(Page::SHOWCASE_SLUG_SUFFIX)
        @page.position = 0
      else
        suffix = normalized_slug_suffix
        if suffix.blank?
          @page.errors.add(:slug, SLUG_REQUIRED_MESSAGE)
          return
        end

        @page.slug = @event.page_slug_for(suffix)
        if suffix == Page::SHOWCASE_SLUG_SUFFIX
          @page.position = 0
          @page.show_in_navigation = true
        end
      end
    end

    def default_page_description
      @event.description.presence || @event.title
    end

    def showcase_page?(page)
      page.event_showcase?
    end

    def ordered_custom_pages
      scope = @event.ordered_pages
      showcase = @event.main_page
      scope = scope.where.not(id: showcase.id) if showcase
      scope.lock.to_a
    end
  end
end
