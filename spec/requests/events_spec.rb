require "rails_helper"

RSpec.describe "Events" do
  let!(:published_event) { create(:event, title: "Super Cool Launch Event", published: true) }
  let!(:draft_event)     { create(:event, title: "Secret Internal Test", published: false) }

  describe "GET /events" do
    it "renders the index successfully, displaying only published events" do
      get events_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(published_event.title)
      expect(response.body).not_to include(draft_event.title)
      expect(response.body).to include("Upcoming Events")
      expect(response.body).to include("View on Calendar")
      expect(response.body).to include(calendar_path)
      expect(response.body).to include(meetups_path)
      expect(response.body).to include(conferences_path)
    end

    it "filters by type_of when a valid type_of param is given" do
      meetup = create(:event, title: "Ruby Meetup", type_of: :meetup, published: true)

      get events_path(type_of: "meetup")

      expect(response).to have_http_status(:success)
      expect(response.body).to include(meetup.title)
      expect(response.body).not_to include(published_event.title)
    end

    it "renders gradient background for events without cover image" do
      get events_path
      expect(response.body).to include("linear-gradient(135deg,")
    end

    it "renders cover image when an event has one attached" do
      image_file = fixture_file_upload(Rails.root.join("spec/fixtures/files/800x600.png"), "image/png")
      published_event.update!(cover_image: image_file)

      get events_path
      expect(response.body).to include(published_event.cover_image.url)
    end
  end

  describe "GET /meetups" do
    it "renders upcoming and past published meetups without unrelated event types or drafts" do
      upcoming_meetup = create(:event, title: "NYC Ruby Meetup", type_of: :meetup, published: true,
                                       start_time: 2.days.from_now, end_time: 3.days.from_now,
                                       data: { "location" => "New York, NY" })
      past_meetup = create(:event, title: "Past JS Meetup", type_of: :meetup, published: true,
                                   start_time: 5.days.ago, end_time: 4.days.ago)
      draft_meetup = create(:event, title: "Draft Meetup", type_of: :meetup, published: false)
      conference = create(:event, title: "Annual Conf", type_of: :conference, published: true)

      get meetups_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Meetups")
      expect(response.body).to include(upcoming_meetup.title)
      expect(response.body).to include("New York, NY")
      expect(response.body).to include(past_meetup.title)
      expect(response.body).not_to include(draft_meetup.title)
      expect(response.body).not_to include(conference.title)
      expect(response.body).to include(calendar_path(type_of: "meetup"))
    end

    it "renders an empty state when no upcoming meetups exist" do
      get meetups_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("views.events.landings.meetup.no_upcoming"))
      expect(response.body).to include(events_path)
    end
  end

  describe "GET /conferences" do
    it "renders upcoming and past published conferences without unrelated event types or drafts" do
      upcoming_conf = create(:event, title: "ForemConf 2026", type_of: :conference, published: true,
                                     start_time: 5.days.from_now, end_time: 7.days.from_now,
                                     data: { "location" => "Chicago, IL" })
      past_conf = create(:event, title: "ForemConf 2025", type_of: :conference, published: true,
                                 start_time: 10.days.ago, end_time: 8.days.ago)
      draft_conf = create(:event, title: "Secret Conf", type_of: :conference, published: false)
      meetup = create(:event, title: "Local Meetup", type_of: :meetup, published: true)

      get conferences_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Conferences")
      expect(response.body).to include(upcoming_conf.title)
      expect(response.body).to include("Chicago, IL")
      expect(response.body).to include(past_conf.title)
      expect(response.body).not_to include(draft_conf.title)
      expect(response.body).not_to include(meetup.title)
      expect(response.body).to include(calendar_path(type_of: "conference"))
    end

    it "renders an empty state when no upcoming conferences exist" do
      get conferences_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("views.events.landings.conference.no_upcoming"))
      expect(response.body).to include(events_path)
    end
  end

  describe "GET /events/:id" do
    context "when requesting a published event" do
      it "renders the show view successfully with og:image meta tags" do
        # `event_path` natively uses the overloaded `to_param` (slug) we built!
        get event_path(published_event.event_name_slug, published_event.event_variation_slug)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(published_event.title)
        expect(response.body).to include("property=\"og:image\"")
        expect(response.body).to include("name=\"twitter:image:src\"")
      end

      context "when forced_live state is passed" do
        it "renders the show view indicating that forced live mode is enabled" do
          get event_path(published_event.event_name_slug, published_event.event_variation_slug),
              params: { state: "forced_live" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include("IS_FORCED_LIVE = true;")
        end
      end

      context "when the event has chat_url data" do
        it "renders the chat iframe and dark mode synchronization script" do
          published_event.update!(data: { "chat_url" => "https://www.youtube.com/live_chat?v=12345" })

          get event_path(published_event.event_name_slug, published_event.event_variation_slug)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("id=\"chat-frame\"")
          expect(response.body).to include("dark_theme")
          expect(response.body).to include("darkpopout")
        end
      end

      context "when the event has associated articles via tags" do
        let(:tag) { create(:tag, name: "awstest") }
        let(:article) { create(:article, title: "A Custom Event Article", tag_list: tag.name, published: true) }

        before do
          published_event.tags << tag
          article # force article creation in DB so it can be queried
        end

        it "renders the articles with their tags successfully without throwing NoMethodError" do
          get event_path(published_event.event_name_slug, published_event.event_variation_slug)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("A Custom Event Article")
          expect(response.body).to include(article.path)
          expect(response.body).to include("##{tag.name}")
        end

        it "batches article authors, skips unrendered article columns, and avoids duplicate tag/signup queries" do
          second_author = create(:user)
          second_article = create(
            :article, user: second_author, title: "Second Event Article", tag_list: tag.name, published: true,
          )
          viewer = create(:user)
          login_as(viewer)

          queries = []
          callback = lambda { |_name, _start, _finish, _id, payload|
            sql = payload[:sql].to_s
            queries << sql unless payload[:name] == "SCHEMA" || sql.match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/)
          }

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get event_path(published_event.event_name_slug, published_event.event_variation_slug)
          end

          expect(response).to have_http_status(:success)
          expect(response.body).to include(
            CGI.escapeHTML(article.user.name),
            CGI.escapeHTML(second_article.user.name),
          )

          article_queries = queries.grep(/FROM "articles"/)
          expect(article_queries.size).to eq(1)
          expect(article_queries.first).not_to include("body_markdown", "processed_html", "SELECT \"articles\".*")

          author_queries = queries.grep(/FROM "users" WHERE "users"\."id" IN/)
          expect(author_queries.size).to eq(1)
          expect(queries.grep(/FROM "users" WHERE "users"\."id" = \$1 LIMIT/)).to be_empty

          expect(queries.grep(/FROM "tags" INNER JOIN "taggings"/).size).to eq(1)
          expect(queries.grep(/FROM "event_signups"/).size).to eq(1)
        end
      end
    end

    context "when an event allows tagged articles" do
      let(:admin) { create(:user, :super_admin) }
      let(:tag) { create(:tag, name: "eventtagtest") }

      it "does not show admin pre-tagged articles or run an extra article query before start_time" do
        upcoming = create(:event, published: true, allow_articles: true, title: "Upcoming Event",
                                  start_time: 2.hours.from_now, end_time: 4.hours.from_now)
        upcoming.tags << tag
        create(:article, user: admin, event: upcoming, title: "Pre-Tagged Secret Post", published: true)
        create(:article, title: "Related Community Post", tag_list: tag.name, published: true)

        queries = []
        callback = lambda { |_name, _start, _finish, _id, payload|
          queries << payload[:sql].to_s unless payload[:name] == "SCHEMA"
        }

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get event_path(upcoming.event_name_slug, upcoming.event_variation_slug)
        end

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Pre-Tagged Secret Post", "event-articles-container")
        expect(response.body).to include("Related Community Post")
        expect(queries.grep(/FROM "articles"/).size).to eq(1)
      end

      it "shows published tagged articles above related community articles and deduplicates them" do
        live_event = create(:event, published: true, allow_articles: true,
                                    title: "Live Summit",
                                    start_time: 1.hour.ago, end_time: 1.hour.from_now)
        live_event.tags << tag

        event_author = create(:user)
        tagged_low = create(:article, user: event_author, event: live_event, title: "Tagged Lower Score",
                                      tag_list: tag.name, published: true, hotness_score: 10)
        tagged_high = create(:article, user: create(:user), event: live_event, title: "Tagged Top Score",
                                       published: true, hotness_score: 100)
        create(:article, user: event_author, event: live_event, title: "Unpublished Event Draft", published: false)
        create(:article, user: event_author, event: live_event, title: "Scheduled Future Event Post",
                         published: true, published_at: 2.hours.from_now)
        create(:article, user: create(:user), title: "General Community Post", tag_list: tag.name, published: true)

        get event_path(live_event.event_name_slug, live_event.event_variation_slug)

        expect(response).to have_http_status(:success)
        body = response.body
        doc = Nokogiri::HTML(body)
        expect(body.index("event-articles-container")).to be < body.index("feed-container")
        expect(doc.at_css("#event-articles-container").css(".article-title").map(&:text)).to eq(
          [tagged_high.title, tagged_low.title],
        )
        expect(doc.at_css("#feed-container").css(".article-title").map(&:text)).to eq(["General Community Post"])
        expect(body).not_to include("Unpublished Event Draft", "Scheduled Future Event Post")
      end

      it "renders quickie (status) posts in tweet-style feed cards alongside full articles" do
        live_event = create(:event, published: true, allow_articles: true, title: "Quickie Event",
                                    start_time: 1.hour.ago, end_time: 1.hour.from_now)
        quickie_author = create(:user, username: "quickiedev", name: "Quickie Dev")
        full_author = create(:user, username: "longformdev", name: "Longform Dev")

        quickie = create(:published_article, user: quickie_author, event: live_event, type_of: :status,
                                             title: "Keynote just kicked off!\n\nLoving the live demo.",
                                             body_markdown: "", tag_list: "", hotness_score: 50)
        quickie.update_column(:processed_html, '<p><img src="https://example.com/demo.png" alt="Demo slide"></p>')
        create(:article, user: full_author, event: live_event, type_of: :full_post,
                         title: "Deep Dive Recap", tag_list: "ruby",
                         published: true, hotness_score: 20)

        get event_path(live_event.event_name_slug, live_event.event_variation_slug)

        expect(response).to have_http_status(:success)
        doc = Nokogiri::HTML(response.body)
        status_card = doc.at_css(".event-feed-item--status")
        article_card = doc.at_css(".event-feed-item--article")

        expect(status_card.text).to include("@quickiedev", "Keynote just kicked off!", "Loving the live demo.")
        expect(status_card.at_css(".event-feed-item__preview img")["src"]).to include("demo.png")
        expect(status_card.at_css(".event-feed-item__tags")).to be_nil
        expect(article_card.text).to include("@longformdev", "Deep Dive Recap", "#ruby", "Article")
      end

      it "batches authors across event and community articles without loading body columns" do
        live_event = create(:event, published: true, allow_articles: true, title: "Batched Summit",
                                    start_time: 1.hour.ago, end_time: 1.hour.from_now)
        live_event.tags << tag
        create(:article, user: create(:user), event: live_event, title: "Event Author Post", published: true)
        create(:article, user: create(:user), title: "Community Author Post", tag_list: tag.name, published: true)

        queries = []
        callback = lambda { |_name, _start, _finish, _id, payload|
          sql = payload[:sql].to_s
          queries << sql unless payload[:name] == "SCHEMA" || sql.match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/)
        }

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get event_path(live_event.event_name_slug, live_event.event_variation_slug)
        end

        expect(response).to have_http_status(:success)
        expect(queries.grep(/FROM "users" WHERE "users"\."id" IN/).size).to eq(1)
        expect(queries.grep(/FROM "users" WHERE "users"\."id" = \$1 LIMIT/)).to be_empty
        expect(queries.grep(/FROM "articles"/).join("\n")).not_to include(
          "body_markdown", "processed_html", 'SELECT "articles".*'
        )
      end

      it "continues showing published tagged articles after the event ends and hides them when toggled off" do
        ended_event = create(:event, published: true, allow_articles: true, title: "Ended Conf",
                                     type_of: :conference,
                                     start_time: 4.hours.ago, end_time: 1.hour.ago)
        ended_event.tags << tag
        create(:article, user: admin, event: ended_event, title: "Conference Recap Post",
                         tag_list: "otherunrelatedtag", published: true)

        get event_path(ended_event.event_name_slug, ended_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("event-articles-container", "Conference Recap Post")

        ended_event.update!(allow_articles: false)
        get event_path(ended_event.event_name_slug, ended_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("event-articles-container", "Conference Recap Post")
      end

      it "renders nothing extra when allow_articles is enabled but no published articles are tagged" do
        live_event = create(:event, published: true, allow_articles: true, title: "Empty Articles Event",
                                    start_time: 1.hour.ago, end_time: 1.hour.from_now)
        create(:article, user: admin, event: live_event, title: "Draft Only Post", published: false)

        get event_path(live_event.event_name_slug, live_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("event-articles-container", "Draft Only Post")
      end

      it "renders event-tagged articles on challenge event pages when enabled and published" do
        challenge = create(:event, published: true, type_of: :challenge, allow_articles: true,
                                   title: "Build Challenge",
                                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
        create(:article, user: admin, event: challenge, title: "Challenge Kickoff Article", published: true)

        get event_path(challenge.event_name_slug, challenge.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("event-articles-container", "Challenge Kickoff Article")
      end
    end

    context "when requesting an event that delegates to a page" do
      let(:delegated_page) { create(:page, slug: "delegated-page") }
      let!(:delegated_event) { create(:event, published: true, delegate_to_page: true, page: delegated_page) }

      it "redirects to the delegated page's path" do
        get event_path(delegated_event.event_name_slug, delegated_event.event_variation_slug)
        expect(response).to redirect_to(delegated_page.path)
      end
    end

    context "when requesting a challenge event" do
      let!(:challenge_event) { create(:event, published: true, type_of: :challenge, title: "Game Jam Challenge") }

      it "renders legacy data body_markdown when the body column is blank" do
        challenge_event.update!(data: { "body_markdown" => "Legacy **rules**" })
        get event_path(challenge_event.event_name_slug, challenge_event.event_variation_slug)
        expect(response.body).to include("<strong>rules</strong>")
      end

      it "prefers the body_markdown column over legacy data" do
        challenge_event.update!(body_markdown: "New **agenda**", data: { "body_markdown" => "Legacy **rules**" })
        get event_path(challenge_event.event_name_slug, challenge_event.event_variation_slug)
        expect(response.body).to include("<strong>agenda</strong>")
        expect(response.body).not_to include("Legacy")
      end

      it "renders the challenge template" do
        get event_path(challenge_event.event_name_slug, challenge_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Challenges")
        expect(response.body).to include(challenge_event.title)
        expect(response.body).to include("Challenge Status:")
      end
    end

    context "when requesting a meetup or conference event" do
      let(:org) { create(:organization, name: "Dev Community Org") }
      let!(:meetup_event) do
        create(:event, published: true, type_of: :meetup, title: "Boston Builders Meetup",
                       primary_stream_url: nil, organization: org,
                       body_markdown: "## Agenda\n\nNetworking and lightning talks.",
                       data: { "location" => "Boston, MA", "format" => "in-person",
                               "registration_url" => "https://example.com/rsvp" })
      end
      let!(:conference_event) do
        create(:event, published: true, type_of: :conference, title: "Global Dev Summit",
                       primary_stream_url: "https://youtube.com/watch?v=abcdefghijk",
                       data: { "location" => "Austin, TX", "website_url" => "javascript:alert(1)" })
      end

      it "renders a gathering page for meetups without a stream placeholder" do
        get event_path(meetup_event.event_name_slug, meetup_event.event_variation_slug)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(
          meetup_event.title, meetups_path, "Boston, MA", "IN-PERSON",
          "Dev Community Org", "https://example.com/rsvp", "Networking and lightning talks."
        )
        expect(response.body).not_to include("Stream URL not configured.")
      end

      it "renders a gathering page for conferences, includes stream player when configured, and strips unsafe URLs" do
        get event_path(conference_event.event_name_slug, conference_event.event_variation_slug)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(conference_event.title)
        expect(response.body).to include(conferences_path)
        expect(response.body).to include("Austin, TX")
        expect(response.body).to include("CONFERENCE")
        expect(response.body).to include("player-container-post-#{conference_event.id}")
        expect(response.body).not_to include("javascript:alert(1)")
      end
    end

    context "when an event has owned pages and optional showcase" do
      let!(:stream_event) do
        create(:event, published: true, type_of: :live_stream, title: "Stream Event",
                       event_name_slug: "stream-evt", event_variation_slug: "2026")
      end
      let!(:challenge_event) do
        create(:event, published: true, type_of: :challenge, title: "Challenge Event",
                       event_name_slug: "challenge-evt", event_variation_slug: "2026")
      end
      let!(:conf_event) do
        create(:event, published: true, type_of: :conference, title: "Conf Event",
                       event_name_slug: "conf-evt", event_variation_slug: "2026",
                       description: "Conference summary")
      end

      it "renders custom pages as tabs past the first Overview view without altering the default view" do
        schedule = create(:page, event: conf_event, slug: conf_event.page_slug_for("schedule"),
                                 title: "Schedule", body_markdown: "## Day 1 Schedule", position: 1)
        create(:page, event: conf_event, slug: conf_event.page_slug_for("hidden"),
                      title: "Hidden Notes", body_markdown: "Internal agenda", show_in_navigation: false)
        create(:page, event: conf_event, slug: conf_event.embed_page_slug_for("widget"),
                      title: "Interactive Widget", template: Page::EMBED_HTML_TEMPLATE,
                      body_markdown: nil, body_html: "<p>Interactive Widget</p>")

        get event_path(conf_event.event_name_slug, conf_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("event-tab-nav", "Overview", "Schedule", "Conference summary")
        expect(response.body).to include('aria-current="page"')
        expect(response.body).not_to include("aria-current=&quot;page&quot;")
        expect(Nokogiri::HTML(response.body).at_css("#event-tab-nav").text).not_to include(
          "Hidden Notes", "Interactive Widget"
        )

        get event_custom_page_path(conf_event.event_name_slug, conf_event.event_variation_slug, "schedule")
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Day 1 Schedule", schedule.title, conf_event.title)
        expect(response.body).not_to include("aria-current=&quot;page&quot;")
      end

      it "serves hidden non-navigation event pages directly at their custom path" do
        create(:page, event: conf_event, slug: conf_event.page_slug_for("hidden"),
                      title: "Hidden Notes", body_markdown: "Internal agenda", show_in_navigation: false)

        get event_custom_page_path(conf_event.event_name_slug, conf_event.event_variation_slug, "hidden")
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Internal agenda")
      end

      it "works across live_stream, challenge, and conference templates when Showcase is selected" do
        [
          [stream_event, "Live Stream", "player-container-post-#{stream_event.id}"],
          [challenge_event, "Challenge Details", "Challenge Status:"],
          [conf_event, "Event Details", I18n.t("views.events.gathering.register_heading")],
        ].each do |evt, expected_native_tab, expected_native_marker|
          create(:page, event: evt, slug: evt.page_slug_for("readme"), title: "Event Showcase",
                        body_markdown: "## Welcome Showcase for #{evt.title}", position: 0)
          create(:page, event: evt, slug: evt.page_slug_for("faq"), title: "FAQ",
                        body_markdown: "## Event FAQ", position: 1)

          get event_path(evt.event_name_slug, evt.event_variation_slug)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(
            "Welcome Showcase for #{evt.title}", "Event Showcase", "FAQ", expected_native_tab
          )
          expect(response.body).not_to include(expected_native_marker)

          get event_path(evt.event_name_slug, evt.event_variation_slug, mode: "overview")
          expect(response).to have_http_status(:success)
          expect(response.body).to include(evt.title, expected_native_tab, expected_native_marker)
          expect(response.body).not_to include("Welcome Showcase for #{evt.title}")
        end
      end

      it "omits feature-flag-inaccessible pages from event tabs and showcase landing" do
        public_showcase = create(
          :page, event: conf_event, slug: conf_event.page_slug_for("readme"),
                 title: "Gated Showcase", body_markdown: "Showcase body", position: 0
        )
        gated_tab = create(
          :page, event: conf_event, slug: conf_event.page_slug_for("vip"),
                 title: "VIP Track", body_markdown: "VIP only", position: 1
        )
        create(
          :page, event: conf_event, slug: conf_event.page_slug_for("faq"),
                 title: "Open FAQ", body_markdown: "Public FAQ", position: 2
        )

        FeatureFlag.add(public_showcase.feature_flag_name)
        FeatureFlag.add(gated_tab.feature_flag_name)

        get event_path(conf_event.event_name_slug, conf_event.event_variation_slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Conference summary", "Open FAQ")
        expect(response.body).not_to include("Showcase body")
        tab_nav_text = Nokogiri::HTML(response.body).at_css("#event-tab-nav").text
        expect(tab_nav_text).not_to include("Gated Showcase", "VIP Track")
      ensure
        FeatureFlag.remove(public_showcase.feature_flag_name) if public_showcase
        FeatureFlag.remove(gated_tab.feature_flag_name) if gated_tab
      end

      it "supports embedded view mode, hides embed_html from /p/ and PagesController, and enforces draft access" do
        create(:page, event: conf_event, slug: conf_event.page_slug_for("guide"),
                      title: "Guide", body_markdown: "Embedded guide body")
        create(:page, event: conf_event, slug: conf_event.embed_page_slug_for("widget"),
                      title: "Widget", template: Page::EMBED_HTML_TEMPLATE,
                      body_markdown: nil, body_html: "<p>Widget</p>")

        get event_custom_page_path(conf_event.event_name_slug, conf_event.event_variation_slug, "guide"),
            params: { mode: "embed" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Embedded guide body")
        expect(response.body).not_to include("event-tab-nav")

        expect do
          get event_custom_page_path(conf_event.event_name_slug, conf_event.event_variation_slug, "widget")
        end.to raise_error(ActiveRecord::RecordNotFound)

        expect do
          get "/#{conf_event.page_slug_for('guide')}"
        end.to raise_error(ActiveRecord::RecordNotFound)

        draft_evt = create(:event, published: false, event_name_slug: "secret-evt", event_variation_slug: "2026")
        create(:page, event: draft_evt, slug: draft_evt.page_slug_for("notes"), title: "Notes", body_markdown: "Secret")
        expect do
          get event_custom_page_path(draft_evt.event_name_slug, draft_evt.event_variation_slug, "notes")
        end.to raise_error(ActionController::RoutingError, "Not Found")
      end
    end

    context "when requesting a draft event" do
      context "as a logged out user" do
        it "raises a 404 RoutingError as if it does not exist" do
          expect do
            get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
          end.to raise_error(ActionController::RoutingError, "Not Found")
        end
      end

      context "as a regular logged in user" do
        let(:regular_user) { create(:user) }

        before { login_as(regular_user) }

        it "raises a 404 RoutingError to maintain draft secrecy" do
          expect do
            get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
          end.to raise_error(ActionController::RoutingError, "Not Found")
        end
      end

      context "as an admin" do
        let(:admin) { create(:user, :super_admin) }

        before { login_as(admin) }

        it "renders the show view with an unpublished warning banner" do
          get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("This event is not published!")
          expect(response.body).to include("Edit Event")
        end
      end
    end

    context "when an event does not exist" do
      context "and a matching page does not exist" do
        it "raises an ActiveRecord::RecordNotFound implicitly handled as a 404" do
          expect do
            get "/events/does-not-exist/version"
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "and a matching page exists" do
        let!(:fallback_page) do
          create(:page, slug: "events/midnight/april-2-2026", body_markdown: "This is the fallback midnight event page")
        end

        it "renders the page instead of raising a 404" do
          get "/events/midnight/april-2-2026"

          expect(response).to have_http_status(:success)
          expect(response.body).to include("This is the fallback midnight event page")
        end

        it "blocks fallback pages belonging to an unpublished event for non-admins" do
          draft_owner = create(:event, published: false, event_name_slug: "draft-fb", event_variation_slug: "2026")
          fallback_page.update_columns(event_id: draft_owner.id, slug: "events/hidden-slug/2026")

          expect do
            get "/events/hidden-slug/2026"
          end.to raise_error(ActionController::RoutingError, "Not Found")

          login_as(create(:user, :super_admin))
          get "/events/hidden-slug/2026"
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
