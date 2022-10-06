require "rails_helper"

# rubocop:disable RSpec/NestedGroups
RSpec.describe "Stories::TaggedArticlesIndex", type: :request do
  %i[enable disable].each do |method|
    context "when :optimize_article_tag_query is #{method}d" do
      before do
        FeatureFlag.public_send method, :optimize_article_tag_query
      end

      describe "GET /tag/:tag" do
        let(:user) { create(:user) }
        let(:tag) { create(:tag) }
        let(:org) { create(:organization) }
        let(:article) { create(:article, tags: tag.name, score: 5) }
        let(:unsupported_tag) { create(:tag, supported: false) }

        before do
          stub_const("Stories::TaggedArticlesController::SIGNED_OUT_RECORD_COUNT", 10)
          create(:article, tags: tag.name, score: 5)
        end

        context "with caching headers" do
          it "renders page and sets proper headers", :aggregate_failures do
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

            expected_surrogate_control_headers = %w[max-age=600 stale-while-revalidate=30 stale-if-error=86400]
            expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)

            expected_surrogate_key_headers = %W[articles-#{tag}]
            expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
          end

          def sets_nginx_headers
            expect(response.headers["X-Accel-Expires"]).to eq("600")
          end
        end

        it "renders page when tag is not supported but has at least one approved article" do
          create(:article, :past, published: true, approved: true, tags: unsupported_tag,
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
          Article.destroy_all
          tag.update_column(:supported, false)
          expect { get "/t/#{tag.name}" }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "renders not found if there are approved but scheduled posts" do
          create(:article, published: true, approved: true, tags: unsupported_tag, published_at: 1.hour.from_now)
          expect { get "/t/#{unsupported_tag.name}" }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "renders normal page if no articles but tag is supported" do
          Article.destroy_all
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

        context "with user signed in" do
          before do
            sign_in user
          end

          it "shows tags and renders properly", :aggregate_failures do
            get "/t/#{tag.name}"
            expect(response.body).to include("crayons-navigation__item crayons-navigation__item--current")
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

          it "does not render pagination even with many posts" do
            create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}"
            expect(response.body).not_to include('<span class="olderposts-pagenumber">')
          end

          it "includes a link to Relevant", :aggregate_failures do
            get "/t/#{tag.name}/latest"

            # The link should be `/t/tag2` (without a trailing slash) instead of `/t/tag2/`
            expected_tag = "<a data-text=\"Relevant\" href=\"/t/#{tag.name}\""
            expect(response.body).to include(expected_tag)
          end
        end

        context "without user signed in" do
          let(:tag) { create(:tag) }

          it "renders tag index properly with many posts", :aggregate_failures do
            create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
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

          it "renders tag index without pagination when not needed" do
            get "/t/#{tag.name}"

            expect(response.body).not_to include('<span class="olderposts-pagenumber">')
          end

          it "does not include sidebar for page tag" do
            create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}/page/2"
            expect(response.body).not_to include('<div id="sidebar-wrapper-right"')
          end

          it "renders proper page 1", :aggregate_failures do
            create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}/page/1"

            renders_title(tag)
            renders_canonical_url(tag)
          end

          def renders_title(tag)
            expect(response.body).to include("<title>#{tag.name.capitalize} - ")
          end

          def renders_canonical_url(tag)
            expect(response.body).to include("<link rel=\"canonical\" href=\"http://localhost:3000/t/#{tag.name}\" />")
          end

          it "renders proper page 2", :aggregate_failures do
            create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
            get "/t/#{tag.name}/page/2"

            renders_page_2_title(tag)
            renders_page_2_canonical_url(tag)
          end

          def renders_page_2_title(tag)
            expect(response.body).to include("<title>#{tag.name.capitalize} Page 2 - ")
          end

          def renders_page_2_canonical_url(tag)
            expected_tag = "<link rel=\"canonical\" href=\"http://localhost:3000/t/#{tag.name}/page/2\" />"
            expect(response.body).to include(expected_tag)
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
