require "rails_helper"

RSpec.describe "Admin::EventPages" do
  let(:super_admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let(:event) do
    create(
      :event,
      title: "Forem Summit",
      event_name_slug: "forem-summit",
      event_variation_slug: "2026",
      type_of: :conference,
    )
  end

  describe "authorization" do
    it "denies access to regular users" do
      login_as(regular_user)
      expect { get admin_event_pages_path(event) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "allows Event single_resource_admin users" do
      event_admin = create(:user)
      event_admin.add_role(:single_resource_admin, Event)
      login_as(event_admin)

      get admin_event_pages_path(event)
      expect(response).to have_http_status(:success)
    end
  end

  describe "CRUD, showcase toggle, reordering, and preview" do
    before { login_as(super_admin) }

    it "lists markdown pages and embed_html pages on index" do
      create(:page, event: event, slug: event.page_slug_for("schedule"), title: "Schedule")
      create(
        :page,
        event: event,
        slug: event.embed_page_slug_for("widget"),
        title: "Schedule Widget",
        template: Page::EMBED_HTML_TEMPLATE,
        body_markdown: nil,
        body_html: "<div>Widget</div>",
      )

      get admin_event_pages_path(event)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Schedule", "Schedule Widget", event.embed_page_slug_for("widget"))
    end

    it "creates a top-level markdown page and a showcase page" do
      expect do
        post admin_event_pages_path(event), params: {
          page: {
            title: "Speakers",
            slug_suffix: "speakers",
            description: "Keynote speakers",
            body_markdown: "## Speakers"
          }
        }
      end.to change(Page, :count).by(1)

      created = event.pages.last
      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(created.slug).to eq("events/forem-summit/2026/speakers")
      expect(created.showcase?).to be(false)

      post admin_event_pages_path(event), params: {
        page: {
          title: "Welcome",
          slug_suffix: "",
          showcase: "1",
          body_markdown: "# Welcome to Summit"
        }
      }

      showcase_page = event.pages.order(:id).last
      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(showcase_page.slug).to eq("events/forem-summit/2026/readme")
      expect(showcase_page.showcase?).to be(true)
    end

    it "creates and updates sandboxed embed_html pages" do
      expect do
        post admin_event_pages_path(event), params: {
          page: {
            template: Page::EMBED_HTML_TEMPLATE,
            title: "Agenda Widget",
            slug_suffix: "agenda-widget",
            body_html: "<div>Interactive Agenda</div>"
          }
        }
      end.to change(Page, :count).by(1)

      embed_page = event.pages.embed_html.last
      expect(embed_page.slug).to eq("events/forem-summit/2026/embed/agenda-widget")

      patch admin_event_page_path(event, embed_page), params: {
        page: {
          title: "Updated Widget",
          slug_suffix: "agenda-v2",
          body_html: "<div>Updated Agenda</div>"
        }
      }

      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(embed_page.reload.slug).to eq("events/forem-summit/2026/embed/agenda-v2")
      expect(embed_page.body_html).to include("Updated Agenda")
    end

    it "rejects invalid slug suffixes on markdown and embed pages" do
      expect do
        post admin_event_pages_path(event), params: {
          page: { title: "Bad", slug_suffix: "!!!", body_markdown: "Body" }
        }
      end.not_to change(Page, :count)
      expect(response).to have_http_status(:unprocessable_entity)

      expect do
        post admin_event_pages_path(event), params: {
          page: { template: Page::EMBED_HTML_TEMPLATE, title: "Bad Embed", slug_suffix: "!!!", body_html: "<p>Hi</p>" }
        }
      end.not_to change(Page, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "toggles showcase status and promotes hidden pages cleanly" do
      page_one = create(:page, event: event, slug: event.page_slug_for("one"), title: "One", showcase: true)
      page_two = create(
        :page,
        event: event,
        slug: event.page_slug_for("two"),
        title: "Two",
        show_in_navigation: false,
      )

      patch toggle_showcase_admin_event_page_path(event, page_two)

      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(page_one.reload.showcase?).to be(false)
      expect(page_two.reload).to have_attributes(showcase: true, show_in_navigation: true)

      patch toggle_showcase_admin_event_page_path(event, page_two)
      expect(page_two.reload.showcase?).to be(false)
    end

    it "serializes showcase selection via the parent event lock on create, update, and toggle" do
      first = create(:page, event: event, slug: event.page_slug_for("first"), title: "First", showcase: true)
      second = create(:page, event: event, slug: event.page_slug_for("second"), title: "Second")
      third_params = {
        page: { title: "Third", slug_suffix: "third", body_markdown: "## Third", showcase: "1" }
      }

      allow(Event).to receive(:find).and_return(event)
      allow(event).to receive(:with_lock).and_call_original

      post admin_event_pages_path(event), params: third_params
      expect(response).to redirect_to(admin_event_pages_path(event))

      patch admin_event_page_path(event, second), params: {
        page: { title: "Second Updated", slug_suffix: "second", body_markdown: "## Two", showcase: "1" }
      }
      expect(response).to redirect_to(admin_event_pages_path(event))

      patch toggle_showcase_admin_event_page_path(event, first)
      expect(response).to redirect_to(admin_event_pages_path(event))

      expect(event).to have_received(:with_lock).exactly(3).times
      expect(first.reload.showcase?).to be(true)
      expect(second.reload.showcase?).to be(false)
    end

    it "rebuilds ordinary page slugs against a concurrently renamed event and skips locking unchanged-slug updates" do
      stale_event = Event.find(event.id)
      allow(Event).to receive(:find).and_return(stale_event)
      allow(stale_event).to receive(:reload).and_wrap_original do |method, **kwargs|
        Event.where(id: event.id).update_all(event_name_slug: "renamed-conf")
        method.call(**kwargs)
      end

      post admin_event_pages_path(event), params: {
        page: { title: "Schedule", slug_suffix: "schedule", body_markdown: "## Schedule" }
      }

      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(stale_event).to have_received(:reload).with(lock: "FOR SHARE")
      created = event.reload.pages.find_by!(title: "Schedule")
      expect(created.slug).to eq("events/renamed-conf/#{event.event_variation_slug}/schedule")

      allow(stale_event).to receive(:reload).and_call_original
      patch admin_event_page_path(event, created), params: {
        page: { title: "Updated Schedule", slug_suffix: "schedule", body_markdown: "## Updated" }
      }
      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(stale_event).to have_received(:reload).with(lock: "FOR SHARE").once
    end

    it "redirects with an alert instead of raising when unsetting showcase fails validation" do
      showcase = create(:page, event: event, slug: event.page_slug_for("readme"), title: "Showcase", showcase: true)
      showcase.update_column(:title, "")

      patch toggle_showcase_admin_event_page_path(event, showcase)

      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(flash[:alert]).to be_present
      expect(showcase.reload.showcase?).to be(true)
    end

    it "reorders non-showcase markdown pages" do
      first = create(:page, event: event, slug: event.page_slug_for("first"), title: "First", position: 1)
      second = create(:page, event: event, slug: event.page_slug_for("second"), title: "Second", position: 2)

      patch reorder_admin_event_page_path(event, second), params: { direction: "up" }

      expect(response).to redirect_to(admin_event_pages_path(event))
      expect(event.ordered_pages.ids).to eq([second.id, first.id])
    end

    it "previews markdown and sandboxed embed_html" do
      post preview_admin_event_pages_path(event), params: { body_markdown: "## Preview Title" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["processed_html"]).to include("Preview Title")

      post preview_admin_event_pages_path(event), params: { body_html: "<p>Sandboxed Preview</p>" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wrapped_html"]).to include("Sandboxed Preview")
    end

    it "deletes an event page" do
      page = create(:page, event: event, slug: event.page_slug_for("temp"), title: "Temp")

      expect do
        delete admin_event_page_path(event, page)
      end.to change(Page, :count).by(-1)

      expect(response).to redirect_to(admin_event_pages_path(event))
    end
  end
end
