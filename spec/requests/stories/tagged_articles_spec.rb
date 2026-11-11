require "rails_helper"

# rubocop:disable RSpec/NestedGroups
RSpec.describe "Stories::TaggedArticlesIndex" do
  %i[enable disable].each do |method|
    context "when :optimize_article_tag_query is #{method}d" do
      before do
        FeatureFlag.public_send method, :optimize_article_tag_query
      end

      describe "GET /tag/:tag" do
        let(:user) { create(:user) }
        let(:tag) { create(:tag) }
        let(:org) { create(:organization) }
        let(:article) { create(:article, user: user, tags: tag.name, score: 5) }
        let(:unsupported_tag) { create(:tag, supported: false) }

        before do
          stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 10)
        end

        context "with caching headers" do
          it "renders page and sets proper headers", :aggregate_failures do
            article
            get "/t/#{tag.name}"

            renders_page
            sets_fastly_headers
            sets_nginx_headers
          end

          def renders_page
            expect(response).to have_http_status(:ok)
            expect(response.body).to include(tag.name)
          end

          def sets_fastly_headers
            expected_cache_control_headers = %w[public no-cache]
            expect(response.headers["Cache-Control"].split(", ")).to match_array(expected_cache_control_headers)

            expected_surrogate_control_headers = %w[max-age=86400 stale-while-revalidate=1000 stale-if-error=86400]
            expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)

            # articles/139
            expected_surrogate_key_headers = ["articles/#{Article.last.id} tags/#{tag.id} tag-#{tag.name}-home"]
            expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
          end

          def sets_nginx_headers
            expect(response.headers["X-Accel-Expires"]).to eq("86400")
          end

          it "tags timeframe and latest tag feeds with dedicated surrogate keys", :aggregate_failures do
            article

            get "/t/#{tag.name}/top/week"
            expect(response.headers["Surrogate-Key"].split).to include(
              article.record_key, tag.record_key, "tag-#{tag.name}-top-week"
            )

            get "/t/#{tag.name}/latest"
            expect(response.headers["Surrogate-Key"].split).to include(
              article.record_key, tag.record_key, "tag-#{tag.name}-latest"
            )
          end

          it "tags alias redirects with the aliased tag surrogate key", :aggregate_failures do
            aliased_tag = create(:tag, name: "jsalias", alias_for: tag.name)

            get "/t/#{aliased_tag.name}"
            expect(response).to have_http_status(:moved_permanently)
            expect(response.headers["Surrogate-Key"].split).to include(
              aliased_tag.record_key, "tag-#{aliased_tag.name}-home"
            )
          end
        end

        it "renders the tags stylesheet under both standard and internal navigation" do
          get "/t/#{tag.name}"
          expect(response.body).to include('href="/assets/tags')

          get "/t/#{tag.name}", params: { i: "i" }
          expect(response.body).to include('href="/assets/tags')
        end

        it "renders stories without loading processed_html", :aggregate_failures do
          article
          queries = []
          callback = lambda do |*, payload|
            queries << payload[:sql] if payload[:sql].include?("\"articles\".\"title\"")
          end
          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get "/t/#{tag.name}"
          end

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(CGI.escapeHTML(article.title))
          expect(queries).not_to be_empty
          expect(queries.grep(/processed_html/)).to be_empty
        end

        it "renders page when tag is not supported but has at least one approved article" do
          create(:article, :past, user: user, published: true, approved: true, tags: unsupported_tag,
                                  past_published_at: 5.years.ago)

          get "/t/#{unsupported_tag.name}/top/week"

          expect(response).to be_successful

          get "/t/#{unsupported_tag.name}/top/month"
          expect(response).to be_successful

          get "/t/#{unsupported_tag.name}/top/year"
          expect(response).to be_successful

          get "/t/#{unsupported_tag.name}/top/infinity"
          expect(response).to be_successful
        end

        it "returns not found if no published posts and tag not supported" do
          expect { get "/t/#{unsupported_tag.name}" }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "renders not found if there are approved but scheduled posts" do
          create(:article, user: user, published: true, approved: true, tags: unsupported_tag,
                           published_at: 1.hour.from_now)
          expect { get "/t/#{unsupported_tag.name}" }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "handles non-basic feed strategy" do
          allow(Settings::UserExperience).to receive(:feed_strategy).and_return("rich")
          allow(Rails.cache).to receive(:fetch).and_call_original

          get "/t/#{tag.name}"
          expect(response.body).to include(tag.name)
          expected_args = ["#{tag.cache_key}/article-cached-tagged-count", { expires_in: 72.hours }]
          expect(Rails.cache).to have_received(:fetch).with(*expected_args).once
        end

        it "does not fetch or count published articles for unsupported tags", :aggregate_failures do
          create(:article, user: user, published: true, approved: true, tags: unsupported_tag, score: 5)
          allow(Rails.cache).to receive(:fetch).and_call_original

          get "/t/#{unsupported_tag.name}"

          expect(response).to have_http_status(:ok)
          expect(Rails.cache).not_to have_received(:fetch).with(
            "#{unsupported_tag.cache_key}/article-cached-tagged-count",
            { expires_in: 72.hours },
          )
        end

        it "skips the existence query for unsupported tags when the page has stories", :aggregate_failures do
          tagged_article = create(:article, user: user, published: true, approved: true, tags: unsupported_tag,
                                            score: 5)
          create(:context_note, article: tagged_article, content: "first tag note")
          create(:context_note, article: tagged_article, content: "second tag note")
          queries = []
          callback = ->(*, payload) { queries << payload[:sql] }
          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get "/t/#{unsupported_tag.name}"
          end

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(CGI.escapeHTML(tagged_article.title), "first tag note")
          expect(response.body).not_to include("second tag note")
          expect(queries.grep(/SELECT 1 AS one FROM "articles"/)).to be_empty
          expect(queries.grep(/FROM "context_notes"/).size).to eq(1)
          expect(queries.grep(/FROM "context_notes"/).first).to include('ORDER BY "context_notes"."id" ASC')
        end

        it "renders normal page if no articles but tag is supported" do
          expect { get "/t/#{tag.name}" }.not_to raise_error
        end

        it "renders page with top/week etc." do
          get "/t/#{tag.name}/top/week"
          expect(response.body).to include(tag.name)
          get "/t/#{tag.name}/top/month"
          expect(response.body).to include(tag.name)
          get "/t/#{tag.name}/top/year"
          expect(response.body).to include(tag.name)
          get "/t/#{tag.name}/top/infinity"
          expect(response.body).to include(tag.name)
        end

        it "displays articles with score > -20 on top/week", :aggregate_failures do
          article
          bad_article = create(:article, user: user, tags: tag.name, score: -30)
          get "/t/#{tag.name}/top/week"
          expect(response.body).to include(CGI.escapeHTML(article.title))
          expect(response.body).not_to include(CGI.escapeHTML(bad_article.title))
        end

        it "includes articles older than 5 years on top/infinity" do
          ancient_article = create(:article, :past, user: user, tags: tag.name, score: 500,
                                                    past_published_at: 6.years.ago)
          get "/t/#{tag.name}/top/infinity"
          expect(response.body).to include(CGI.escapeHTML(ancient_article.title))
        end

        it "renders tag after alias change" do
          tag2 = create(:tag, alias_for: tag.name)
          get "/t/#{tag2.name}"
          expect(response.body).to redirect_to "/t/#{tag.name}"
          expect(response).to have_http_status(:moved_permanently)
        end

        it "shows meta keywords if set" do
          allow(Settings::General).to receive(:meta_keywords).and_return({ tag: "software engineering, ruby" })
          get "/t/#{tag.name}"
          expect(response.body)
            .to include("<meta name=\"keywords\" content=\"software engineering, ruby, #{tag.name}\">")
        end

        it "does not show meta keywords if not set" do
          allow(Settings::General).to receive(:meta_keywords).and_return({ tag: "" })
          get "/t/#{tag.name}"
          expect(response.body).not_to include(
            "<meta name=\"keywords\" content=\"software engineering, ruby, #{tag.name}\">",
          )
        end

        context "when the tag has moderators" do
          let(:mod_user) { create(:user, username: "tag_mod_alpha") }
          let(:new_mod_user) { create(:user, username: "tag_mod_beta") }

          before do
            sign_in user
            TagModerators::Add.call(mod_user.id, tag.id)
          end

          it "updates the cached sidebar when a new moderator is added", :aggregate_failures do
            get "/t/#{tag.name}"
            expect(response.body).to include(mod_user.username)
            expect(response.body).not_to include(new_mod_user.username)

            TagModerators::Add.call(new_mod_user.id, tag.id)

            get "/t/#{tag.name}"
            expect(response.body).to include(new_mod_user.username)
          end

          it "updates the cached sidebar when a moderator is removed", :aggregate_failures do
            get "/t/#{tag.name}"
            expect(response.body).to include(mod_user.username)

            TagModerators::Remove.call(mod_user, tag)

            get "/t/#{tag.name}"
            expect(response.body).not_to include(mod_user.username)
          end

          it "loads tag moderators via role_ids without a rolify users_roles join", :aggregate_failures do
            queries = []
            callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
            ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
              get "/t/#{tag.name}"
            end

            expect(response.body).to include(mod_user.username)
            expect(queries.grep(/INNER JOIN "users_roles".*INNER JOIN "roles"/)).to be_empty
          end
        end

        context "with user signed in" do
          before do
            sign_in user
          end

          it "shows tags and renders properly", :aggregate_failures do
            queries = []
            callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
            ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
              get "/t/#{tag.name}"
            end
            expect(response.body).to include("crayons-navigation__item crayons-navigation__item--current")
            expect(queries.grep(/FROM "users_roles"/)).to be_empty
            has_mod_action_button
            does_not_paginate
            sets_remember_token
          end

          def has_mod_action_button
            expect(response.body).to include('class="crayons-btn crayons-btn--outlined mod-action-button fs-s"')
          end

          def does_not_paginate
            expect(response.body).not_to include('<span class="olderposts-pagenumber">')
          end

          def sets_remember_token
            expect(response.cookies["remember_user_token"]).not_to be_nil
          end

          it "renders properly even if site config is private" do
            allow(Settings::UserExperience).to receive(:public).and_return(false)
            get "/t/#{tag.name}"
            expect(response.body).to include("crayons-navigation__item crayons-navigation__item--current")
          end

          it "does not render pagination even with many posts", :aggregate_failures do
            create_list(:article, 6, user: user, featured: true, tags: [tag.name], score: 20)
            allow(Rails.cache).to receive(:fetch).and_call_original

            get "/t/#{tag.name}"

            expect(response.body).not_to include('<span class="olderposts-pagenumber">')
            expect(Rails.cache).not_to have_received(:fetch).with(
              "#{tag.cache_key}/article-cached-tagged-count",
              { expires_in: 72.hours },
            )
          end

          it "includes a link to Relevant", :aggregate_failures do
            get "/t/#{tag.name}/latest"

            # The link should be `/t/tag2` (without a trailing slash) instead of `/t/tag2/`
            expected_tag = "<a data-text=\"Relevant\" href=\"/t/#{tag.name}\""
            expect(response.body).to include(expected_tag)
          end

          it "queries active discuss threads for the sidebar on page 1" do
            discuss_article = create(:article, user: user, tags: "#{tag.name}, discuss", score: 10)
            allow(Articles::ActiveThreadsQuery).to receive(:call).and_call_original

            get "/t/#{tag.name}"

            expect(Articles::ActiveThreadsQuery).to have_received(:call).with(
              tags: [tag.name, "discuss"],
              time_ago: nil,
            ).once
            expect(response.body).to include(CGI.escapeHTML(discuss_article.title))
          end
        end

        context "without user signed in" do
          it "does not execute Articles::ActiveThreadsQuery for signed-out requests" do
            allow(Articles::ActiveThreadsQuery).to receive(:call).and_call_original

            get "/t/#{tag.name}"

            expect(response).to have_http_status(:ok)
            expect(Articles::ActiveThreadsQuery).not_to have_received(:call)
          end

          it "does not query organizations once per org story", :aggregate_failures do
            count_org_queries = lambda do
              org_queries = 0
              callback = lambda do |*, payload|
                org_queries += 1 if payload[:sql].include?("FROM \"organizations\"")
              end
              ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
                get "/t/#{tag.name}"
              end
              org_queries
            end

            create_list(:article, 2, user: user, organization: org, tags: tag.name, score: 5)
            # Warm-up render: the first request pays one-off lookups unrelated to stories.
            count_org_queries.call
            baseline = count_org_queries.call
            expect(response).to have_http_status(:ok)

            create_list(:article, 3, user: user, organization: org, tags: tag.name, score: 5)
            3.times { create(:article, user: user, organization: create(:organization), tags: tag.name, score: 5) }

            expect(count_org_queries.call).to be <= baseline
            expect(response).to have_http_status(:ok)
            expect(response.body).to include(CGI.escapeHTML(org.name))
          end

          it "renders tag index properly with many posts", :aggregate_failures do
            stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 2)
            create_list(:article, 3, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}"

            shows_sign_in_notice
            does_not_include_current_page_link(tag)
            does_not_set_remember_token
            renders_pagination
          end

          def shows_sign_in_notice
            expect(response.body).not_to include("crayons-navigation__item crayons-navigation__item--current")
            expect(response.body).to include("for the ability to sort posts by")
          end

          def does_not_include_current_page_link(tag)
            expect(response.body).to include('<span class="olderposts-pagenumber">1')
            expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/1")
            expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/3")
          end

          def does_not_set_remember_token
            expect(response.cookies["remember_user_token"]).to be_nil
          end

          def renders_pagination
            expect(response.body).to include('<span class="olderposts-pagenumber">')
          end

          it "renders tag index with pagination for supported tags" do
            get "/t/#{tag.name}"

            expect(response.body).to include('<span class="olderposts-pagenumber">')
          end

          it "renders proper page 1", :aggregate_failures do
            get "/t/#{tag.name}/page/1"

            renders_title(tag)
            renders_canonical_url(tag)
          end

          def renders_title(tag)
            expect(response.body).to include("<title>#{tag.name.capitalize} - ")
          end

          def renders_canonical_url(tag)
            expect(response.body).to include("<link rel=\"canonical\" href=\"http://forem.test/t/#{tag.name}\" />")
          end

          it "renders proper page 2 without right sidebar", :aggregate_failures do
            stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 2)
            create_list(:article, 3, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}/page/2"

            expect(response.body).not_to include('<div id="sidebar-wrapper-right"')
            renders_page_2_title(tag)
            renders_page_2_canonical_url(tag)
          end

          def renders_page_2_title(tag)
            expect(response.body).to include("<title>#{tag.name.capitalize} Page 2 - ")
          end

          def renders_page_2_canonical_url(tag)
            expected_tag = "<link rel=\"canonical\" href=\"http://forem.test/t/#{tag.name}/page/2\" />"
            expect(response.body).to include(expected_tag)
          end

          it "returns not found when page is below 1 or exceeds MAX_PAGE", :aggregate_failures do
            article
            expect { get "/t/#{tag.name}/page/0" }.to raise_error(ActiveRecord::RecordNotFound)
            expect do
              get "/t/#{tag.name}/page/#{Stories::TaggedArticlesController::MAX_PAGE + 1}"
            end.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "clamps sidebar pagination links to MAX_PAGE", :aggregate_failures do
            article
            allow(Rails.cache).to receive(:fetch).and_call_original
            allow(Rails.cache).to receive(:fetch)
              .with("#{tag.cache_key}/article-cached-tagged-count", { expires_in: 72.hours })
              .and_return(50_000)

            get "/t/#{tag.name}"

            expect(response).to have_http_status(:ok)
            expected_link = %(<a href="http://forem.test/t/#{tag.name}/page/100" class="olderposts-pagenumber">100</a>)
            expect(response.body).to include(expected_link)
            expect(response.body).not_to include("/page/5000")
          end

          def capture_count_queries(tag_name)
            count_queries = []
            callback = lambda do |*, payload|
              next unless payload[:sql].include?("SELECT COUNT(*)")

              binds = payload[:type_casted_binds]
              binds = binds.call if binds.respond_to?(:call)
              count_queries << { sql: payload[:sql], binds: Array(binds) }
            end
            ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
              get "/t/#{tag_name}"
            end
            count_queries
          end

          def capped_subquery_count?(query, expected_limit)
            match = query[:sql].match(/LIMIT (?:\$(\d+)|(\d+))\b.*subquery_for_count/)
            return false unless match

            match[1] ? query[:binds][match[1].to_i - 1] == expected_limit : match[2].to_i == expected_limit
          end

          it "caps the published article count query at SIGNED_OUT_RECORD_COUNT * MAX_PAGE", :aggregate_failures do
            stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 2)
            stub_const("Stories::TaggedArticlesController::MAX_PAGE", 2)
            create_list(:article, 5, user: user, published: true, tags: [tag.name], score: 20)

            count_queries = capture_count_queries(tag.name)

            expect(response).to have_http_status(:ok)
            expect(count_queries).to include(satisfy { |query| capped_subquery_count?(query, 4) })
            expected_link = %(<a href="http://forem.test/t/#{tag.name}/page/2" class="olderposts-pagenumber">2</a>)
            expect(response.body).to include(expected_link)
            expect(response.body).not_to include("/page/3")
          end

          it "caps the approved article count query when tag requires approval", :aggregate_failures do
            approval_tag = create(:tag, supported: true, requires_approval: true)
            stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 2)
            stub_const("Stories::TaggedArticlesController::MAX_PAGE", 2)
            create_list(:article, 5, user: user, published: true, approved: true, tags: [approval_tag.name], score: 20)

            count_queries = capture_count_queries(approval_tag.name)

            expect(response).to have_http_status(:ok)
            expect(count_queries).to include(satisfy { |query| capped_subquery_count?(query, 4) })
            expect(response.body).to include(
              %(<a href="http://forem.test/t/#{approval_tag.name}/page/2" class="olderposts-pagenumber">2</a>),
            )
            expect(response.body).not_to include("/page/3")
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
