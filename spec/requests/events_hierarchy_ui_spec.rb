require "rails_helper"

RSpec.describe "Event Hierarchy Public UI and Livestream Experience" do
  let(:admin) { create(:user, :super_admin) }
  let(:viewer) { create(:user) }

  describe "conference hero promotion and schedule rendering" do
    let!(:conference) do
      create(:event, type_of: :conference, title: "OpenSource Conf 2026", published: true,
                     start_time: 1.day.ago, end_time: 2.days.from_now,
                     data: { "location" => "San Francisco, CA", "time_zone" => "America/Los_Angeles" })
    end

    it "promotes a live sub-event in the hero with inline player and concurrent live switcher" do
      live_keynote = create(:event, type_of: :live_stream, title: "Live Opening Keynote", published: true,
                                    primary_stream_url: "https://youtube.com/watch?v=abcdefghijk",
                                    start_time: 20.minutes.ago, end_time: 1.hour.from_now)
      live_track_b = create(:event, type_of: :live_stream, title: "Live Track B Deep Dive", published: true,
                                    primary_stream_url: "https://youtube.com/watch?v=1234567890a",
                                    start_time: 10.minutes.ago, end_time: 1.hour.from_now)
      upcoming_talk = create(:event, type_of: :live_stream, title: "Afternoon Scaling Talk", published: true,
                                     start_time: 3.hours.from_now, end_time: 4.hours.from_now)
      draft_session = create(:event, type_of: :live_stream, title: "Secret Draft Session", published: false,
                                     start_time: 5.minutes.ago, end_time: 1.hour.from_now)

      create(:event_membership, parent_event: conference, child_event: live_keynote, role: "Keynote", featured: true)
      create(:event_membership, parent_event: conference, child_event: live_track_b, role: "Track B")
      create(:event_membership, parent_event: conference, child_event: upcoming_talk, role: "Architecture")
      create(:event_membership, parent_event: conference, child_event: draft_session, role: "Internal")

      get event_path(conference.event_name_slug, conference.event_variation_slug)
      expect(response).to have_http_status(:success)

      doc = Nokogiri::HTML(response.body)
      hero = doc.at_css(".event-hero-stage--live")
      expect(hero).to be_present
      expect(hero.text).to include("HAPPENING NOW", "Live Opening Keynote", "Keynote")
      expect(hero.at_css("iframe")["src"]).to include("youtube.com/embed/abcdefghijk")
      expect(hero.text).to include("Also Live Right Now", "Live Track B Deep Dive")
      expect(doc.text).to include("Afternoon Scaling Talk", "Schedule & Sessions")
      expect(response.body).not_to include("Secret Draft Session")
    end

    it "shows upcoming hero with countdown and day-grouped schedule when nothing is live" do
      next_session = create(:event, type_of: :live_stream, title: "First Morning Keynote", published: true,
                                    start_time: 4.hours.from_now, end_time: 5.hours.from_now)
      later_session = create(:event, type_of: :live_stream, title: "Day 2 Fireside Chat", published: true,
                                     start_time: 28.hours.from_now, end_time: 29.hours.from_now)

      create(:event_membership, parent_event: conference, child_event: next_session, role: "Keynote", featured: true)
      create(:event_membership, parent_event: conference, child_event: later_session, role: "Community")

      get event_path(conference.event_name_slug, conference.event_variation_slug)
      expect(response).to have_http_status(:success)

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css(".event-hero-stage--upcoming")).to be_present
      expect(doc.at_css(".event-hero-stage--upcoming").text).to include("UP NEXT", "First Morning Keynote")
      expect(doc.at_css("#event-schedule").text).to include("First Morning Keynote", "Day 2 Fireside Chat")
    end

    it "batches event_signups into a single query for conference and all sub-events" do
      3.times do |i|
        sub = create(:event, type_of: :live_stream, title: "Upcoming Session #{i}", published: true,
                             start_time: (i + 2).hours.from_now, end_time: (i + 3).hours.from_now)
        create(:event_membership, parent_event: conference, child_event: sub, position: i)
      end

      login_as(viewer)
      queries = []
      callback = lambda { |_name, _start, _finish, _id, payload|
        queries << payload[:sql].to_s unless payload[:name] == "SCHEMA"
      }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get event_path(conference.event_name_slug, conference.event_variation_slug)
      end

      expect(response).to have_http_status(:success)
      expect(queries.grep(/FROM "event_signups"/).size).to eq(1)
    end

    it "shows live ribbon on custom conference sub-pages when a sub-event is live" do
      create(:page, event: conference, slug: conference.page_slug_for("speakers"),
                    title: "Speakers", body_markdown: "## Featured Speakers", position: 1)
      live_stream = create(:event, type_of: :live_stream, title: "Live Keynote on Stage", published: true,
                                   start_time: 10.minutes.ago, end_time: 1.hour.from_now)
      create(:event_membership, parent_event: conference, child_event: live_stream, role: "Keynote")

      get event_custom_page_path(conference.event_name_slug, conference.event_variation_slug, "speakers")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Featured Speakers", "HAPPENING NOW", "Live Keynote on Stage")
    end
  end

  describe "draft conference preview for admins" do
    it "allows admins to preview a draft conference with its draft livestream sub-events" do
      draft_conf = create(:event, type_of: :conference, title: "Draft Future Conf", published: false,
                                  start_time: 1.hour.ago, end_time: 2.days.from_now)
      draft_live = create(:event, type_of: :live_stream, title: "Draft Live Keynote", published: false,
                                  start_time: 15.minutes.ago, end_time: 1.hour.from_now)
      create(:event_membership, parent_event: draft_conf, child_event: draft_live, role: "Keynote")

      expect do
        get event_path(draft_conf.event_name_slug, draft_conf.event_variation_slug)
      end.to raise_error(ActionController::RoutingError, "Not Found")

      login_as(admin)
      get event_path(draft_conf.event_name_slug, draft_conf.event_variation_slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This event is not published!", "Draft Live Keynote", "Draft")
    end
  end

  describe "livestream sub-event coming-soon state and parent context" do
    it "renders enhanced coming-soon stage, parent conference bar, and sibling sessions" do
      conference = create(:event, type_of: :conference, title: "Cloud Summit", published: true,
                                  start_time: 1.hour.from_now, end_time: 2.days.from_now)
      future_stream = create(:event, type_of: :live_stream, title: "Distributed Systems Live", published: true,
                                     primary_stream_url: "https://youtube.com/watch?v=abcdefghijk",
                                     start_time: 5.hours.from_now, end_time: 6.hours.from_now)
      next_sibling = create(:event, type_of: :live_stream, title: "Database Internals Live", published: true,
                                    start_time: 7.hours.from_now, end_time: 8.hours.from_now)

      create(:event_membership, parent_event: conference, child_event: future_stream, role: "Main Stage")
      create(:event_membership, parent_event: conference, child_event: next_sibling, role: "Track B")

      get event_path(future_stream.event_name_slug, future_stream.event_variation_slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(
        "Cloud Summit",
        "Part of",
        "COMING SOON",
        "Live stream starts in",
        "Add to Calendar",
        "Database Internals Live",
        "stream-coming-soon",
      )
    end
  end

  describe "public /events index and /calendar hierarchy display" do
    it "keeps sub-events nested on /events while showing parent context when filtered and on /calendar" do
      conference = create(:event, type_of: :conference, title: "MegaConf 2026", published: true,
                                  start_time: 1.hour.ago, end_time: 2.days.from_now)
      sub_stream = create(:event, type_of: :live_stream, title: "MegaConf Live Stream", published: true,
                                  start_time: 15.minutes.ago, end_time: 2.hours.from_now)
      create(:event, type_of: :live_stream, title: "Standalone Weekly Stream", published: true,
                     start_time: 3.hours.from_now, end_time: 4.hours.from_now)

      create(:event_membership, parent_event: conference, child_event: sub_stream, role: "Keynote")

      get events_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("MegaConf 2026", "Standalone Weekly Stream", "1 session", "MegaConf Live Stream")
      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".event-card-title").map { |el| el.text.strip }).to contain_exactly(
        "MegaConf 2026", "Standalone Weekly Stream"
      )

      get events_path(type_of: "live_stream")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("MegaConf Live Stream", "Part of MegaConf 2026")

      get calendar_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("MegaConf Live Stream", "Part of MegaConf 2026")
    end
  end
end
