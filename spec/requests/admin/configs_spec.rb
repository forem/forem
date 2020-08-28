require "rails_helper"

RSpec.describe "/admin/config", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_plus_config) { create(:user, :super_plus_single_resource_admin, resource: Config) }
  let(:confirmation_message) do
    "My username is @#{admin_plus_config.username} and this action is 100% safe and appropriate."
  end

  describe "POST admin/config as a user" do
    before do
      sign_in(user)
    end

    it "bars the regular user to access" do
      expect { post "/admin/config", params: {} }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  # rubocop:disable RSpec/NestedGroups
  describe "POST admin/config" do
    context "when admin has typical admin permissions but not single resource" do
      before do
        sign_in(admin)
      end

      it "does not allow user to update config if they have proper confirmation" do
        expected_image_url = "https://dummyimage.com/300x300"
        expect do
          post "/admin/config", params: { site_config: { favicon_url: expected_image_url },
                                          confirmation: confirmation_message }
        end.to raise_error Pundit::NotAuthorizedError
      end

      it "does not allow user to update config if they do not have proper confirmation" do
        expected_image_url = "https://dummyimage.com/300x300"
        expect do
          post "/admin/config", params: { site_config: { favicon_url: expected_image_url },
                                          confirmation: "Not proper" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when admin has full permissions including single resource" do
      before do
        sign_in(admin_plus_config)
      end

      describe "API tokens" do
        it "updates the health_check_token" do
          token = rand(20).to_s
          post "/admin/config", params: { site_config: { health_check_token: token },
                                          confirmation: confirmation_message }
          expect(SiteConfig.health_check_token).to eq token
        end
      end

      describe "Authentication" do
        it "updates enabled authentication providers" do
          enabled = Array.wrap(Authentication::Providers.available.first.to_s)
          post "/admin/config", params: { site_config: { authentication_providers: enabled },
                                          confirmation: confirmation_message }
          expect(SiteConfig.authentication_providers).to eq(enabled)
        end

        it "strips empty elements" do
          provider = Authentication::Providers.available.first.to_s
          enabled = [provider, "", nil]
          post "/admin/config", params: { site_config: { authentication_providers: enabled },
                                          confirmation: confirmation_message }
          expect(SiteConfig.authentication_providers).to eq([provider])
        end
      end

      describe "Community Content" do
        it "updates the community_description" do
          allow(SiteConfig).to receive(:community_description).and_call_original
          description = "Hey hey #{rand(100)}"
          post "/admin/config", params: { site_config: { community_description: description },
                                          confirmation: confirmation_message }
          expect(SiteConfig.community_description).to eq(description)
        end

        it "updates the community_name" do
          name_magoo = "Hey hey #{rand(100)}"
          post "/admin/config", params: { site_config: { community_name: name_magoo },
                                          confirmation: confirmation_message }
          expect(SiteConfig.community_name).to eq(name_magoo)
        end

        it "updates the community_member_label" do
          name = "developer"
          post "/admin/config", params: { site_config: { community_member_label: name },
                                          confirmation: confirmation_message }
          expect(SiteConfig.community_member_label).to eq(name)
        end

        it "updates the community_action" do
          action = "reading"
          post "/admin/config", params: { site_config: { community_member_label: action },
                                          confirmation: confirmation_message }
          expect(SiteConfig.community_member_label).to eq(action)
        end

        it "updates the community_copyright_start_year" do
          year = "2018"
          post "/admin/config", params: { site_config: { community_copyright_start_year: year },
                                          confirmation: confirmation_message }
          expect(SiteConfig.community_copyright_start_year).to eq(2018)
        end

        it "updates the tagline" do
          description = "Hey hey #{rand(100)}"
          post "/admin/config", params: { site_config: { tagline: description }, confirmation: confirmation_message }
          expect(SiteConfig.tagline).to eq(description)
        end

        it "updates the staff_user_id" do
          post "/admin/config", params: { site_config: { staff_user_id: 22 }, confirmation: confirmation_message }
          expect(SiteConfig.staff_user_id).to eq(22)
        end
      end

      describe "Emails" do
        it "updates email_addresses" do
          expected_email_addresses = {
            business: "partners@example.com",
            privacy: "privacy@example.com",
            members: "members@example.com"
          }
          post "/admin/config", params: { site_config: { email_addresses: expected_email_addresses },
                                          confirmation: confirmation_message }
          expect(SiteConfig.email_addresses[:privacy]).to eq("privacy@example.com")
          expect(SiteConfig.email_addresses[:business]).to eq("partners@example.com")
          expect(SiteConfig.email_addresses[:members]).to eq("members@example.com")
          expect(SiteConfig.email_addresses[:default]).to eq(ApplicationConfig["DEFAULT_EMAIL"])
        end
      end

      describe "Email digest frequency" do
        it "updates periodic_email_digest_max" do
          post "/admin/config", params: { site_config: { periodic_email_digest_max: 1 },
                                          confirmation: confirmation_message }
          expect(SiteConfig.periodic_email_digest_max).to eq(1)
        end

        it "updates periodic_email_digest_min" do
          post "/admin/config", params: { site_config: { periodic_email_digest_min: 3 },
                                          confirmation: confirmation_message }
          expect(SiteConfig.periodic_email_digest_min).to eq(3)
        end

        it "rejects update without proper confirmation" do
          expect do
            post "/admin/config", params: { site_config: { periodic_email_digest_min: 6 },
                                            confirmation: "Incorrect yo!" }
          end.to raise_error ActionController::BadRequest
          expect(SiteConfig.periodic_email_digest_min).not_to eq(6)
        end
      end

      describe "Jobs" do
        it "updates jobs_url" do
          post "/admin/config", params: { site_config: { jobs_url: "www.jobs.com" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.jobs_url).to eq("www.jobs.com")
        end

        it "updates display_jobs_banner" do
          post "/admin/config", params: { site_config: { display_jobs_banner: true },
                                          confirmation: confirmation_message }
          expect(SiteConfig.display_jobs_banner).to eq(true)
        end
      end

      describe "Google Analytics Reporting API v4" do
        it "updates ga_view_id" do
          post "/admin/config", params: { site_config: { ga_view_id: "abc" }, confirmation: confirmation_message }
          expect(SiteConfig.ga_view_id).to eq("abc")
        end
      end

      describe "Images" do
        it "updates main_social_image" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { main_social_image: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.main_social_image).to eq(expected_image_url)
        end

        it "updates favicon_url" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { favicon_url: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.favicon_url).to eq(expected_image_url)
        end

        it "updates logo_png" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { logo_png: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.logo_png).to eq(expected_image_url)
        end

        it "updates logo_svg" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { logo_svg: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.logo_svg).to eq(expected_image_url)
        end

        it "updates secondary_logo_url" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { secondary_logo_url: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.secondary_logo_url).to eq(expected_image_url)
        end

        it "updates left_navbar_svg_icon" do
          expected_svg = "<svg height='100' width='100'><circle cx='50' cy='50' r='40' " \
            "stroke='black' stroke-width='3'/></svg>"
          post "/admin/config", params: { site_config: { left_navbar_svg_icon: expected_svg },
                                          confirmation: confirmation_message }
          expect(SiteConfig.left_navbar_svg_icon).to eq(expected_svg)
        end

        it "updates right_navbar_svg_icon" do
          expected_svg = "<svg height='100' width='100'><circle cx='50' cy='50' r='40' " \
            "stroke='black' stroke-width='1'/></svg>"
          post "/admin/config", params: { site_config: { right_navbar_svg_icon: expected_svg },
                                          confirmation: confirmation_message }
          expect(SiteConfig.right_navbar_svg_icon).to eq(expected_svg)
        end

        it "rejects update without proper confirmation" do
          expected_image_url = "https://dummyimage.com/300x300"
          expect do
            post "/admin/config", params: { site_config: { logo_svg: expected_image_url },
                                            confirmation: "Incorrect yo!" }
          end.to raise_error ActionController::BadRequest
        end

        it "rejects update without any confirmation" do
          expected_image_url = "https://dummyimage.com/300x300"
          expect do
            post "/admin/config", params: { site_config: { logo_svg: expected_image_url },
                                            confirmation: "" }
          end.to raise_error ActionController::ParameterMissing
        end
      end

      describe "Mascot" do
        it "updates the mascot_user_id" do
          expected_mascot_user_id = 2
          post "/admin/config", params: { site_config: { mascot_user_id: expected_mascot_user_id },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_user_id).to eq(expected_mascot_user_id)
        end

        it "updates mascot_image_url" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { mascot_image_url: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_image_url).to eq(expected_image_url)
        end

        it "updates mascot_footer_image_url" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { mascot_footer_image_url: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_footer_image_url).to eq(expected_image_url)
        end

        it "updates the mascot_footer_image_width" do
          expected_default_mascot_footer_image_width = 52
          expected_mascot_footer_image_width = 1002

          expect(SiteConfig.mascot_footer_image_width).to eq(expected_default_mascot_footer_image_width)

          post "/admin/config", params: { site_config:
                                            { mascot_footer_image_width: expected_mascot_footer_image_width },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_footer_image_width).to eq(expected_mascot_footer_image_width)
        end

        it "updates the mascot_footer_image_height" do
          expected_default_mascot_footer_image_height = 120
          expected_mascot_footer_image_height = 3002

          expect(SiteConfig.mascot_footer_image_height).to eq(expected_default_mascot_footer_image_height)

          post "/admin/config", params: { site_config:
                                            { mascot_footer_image_height: expected_mascot_footer_image_height },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_footer_image_height).to eq(expected_mascot_footer_image_height)
        end

        it "updates mascot_image_description" do
          description = "Hey hey #{rand(100)}"
          post "/admin/config", params: { site_config: { mascot_image_description: description },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mascot_image_description).to eq(description)
        end
      end

      describe "Meta Keywords" do
        it "updates meta keywords" do
          expected_keywords = { "default" => "software, people", "article" => "user, experience", "tag" => "bye" }
          post "/admin/config", params: { site_config: { meta_keywords: expected_keywords },
                                          confirmation: confirmation_message }
          expect(SiteConfig.meta_keywords[:default]).to eq("software, people")
          expect(SiteConfig.meta_keywords[:article]).to eq("user, experience")
          expect(SiteConfig.meta_keywords[:tag]).to eq("bye")
        end
      end

      describe "Monetization" do
        it "updates payment pointer" do
          post "/admin/config", params: { site_config: { payment_pointer: "$pay.yo" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.payment_pointer).to eq("$pay.yo")
        end

        it "updates stripe configs" do
          post "/admin/config", params: { site_config: { stripe_api_key: "sk_live_yo",
                                                         stripe_publishable_key: "pk_live_haha" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.stripe_api_key).to eq("sk_live_yo")
          expect(SiteConfig.stripe_publishable_key).to eq("pk_live_haha")
        end

        describe "Shop" do
          it "rejects update to shop_url without proper confirmation" do
            expected_shop_url = "https://qshop.dev.to"

            expect do
              params = { site_config: { shop_url: expected_shop_url }, confirmation: "Incorrect confirmation" }
              post "/admin/config", params: params
            end.to raise_error ActionController::BadRequest

            expect(SiteConfig.shop_url).not_to eq(expected_shop_url)
          end

          it "sets shop_url to nil" do
            previous_shop_url = "some-shop-url"
            post "/admin/config", params: { site_config: { shop_url: "" }, confirmation: confirmation_message }
            expect(SiteConfig.shop_url).to eq("")
            get "/privacy"
            expect(response.body).not_to include(previous_shop_url)
            expect(response.body).not_to include("#{SiteConfig.community_name} Shop")
          end

          it "updates shop url" do
            expected_shop_url = "https://qshop.dev.to"
            post "/admin/config", params: { site_config: { shop_url: expected_shop_url },
                                            confirmation: confirmation_message }
            expect(SiteConfig.shop_url).to eq(expected_shop_url)
            get "/privacy"
            expect(response.body).to include(expected_shop_url)
            expect(response.body).to include("#{SiteConfig.community_name} Shop")
          end
        end
      end

      describe "Newsletter" do
        it "updates mailchimp_newsletter_id" do
          post "/admin/config", params: { site_config: { mailchimp_newsletter_id: "abc" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mailchimp_newsletter_id).to eq("abc")
        end

        it "updates mailchimp_sustaining_members_id" do
          post "/admin/config", params: { site_config: { mailchimp_sustaining_members_id: "abc" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mailchimp_sustaining_members_id).to eq("abc")
        end

        it "updates mailchimp_tag_moderators_id" do
          post "/admin/config", params: { site_config: { mailchimp_tag_moderators_id: "abc" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mailchimp_tag_moderators_id).to eq("abc")
        end

        it "updates mailchimp_community_moderators_id" do
          post "/admin/config", params: { site_config: { mailchimp_community_moderators_id: "abc" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.mailchimp_community_moderators_id).to eq("abc")
        end
      end

      describe "Onboarding" do
        it "updates onboarding_taskcard_image" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { onboarding_taskcard_image: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.onboarding_taskcard_image).to eq(expected_image_url)
        end

        it "updates onboarding_logo_image" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { onboarding_logo_image: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.onboarding_logo_image).to eq(expected_image_url)
        end

        it "updates onboarding_background_image" do
          expected_image_url = "https://dummyimage.com/300x300"
          post "/admin/config", params: { site_config: { onboarding_background_image: expected_image_url },
                                          confirmation: confirmation_message }
          expect(SiteConfig.onboarding_background_image).to eq(expected_image_url)
        end

        it "removes space suggested_tags" do
          post "/admin/config", params: { site_config: { suggested_tags: "hey, haha,hoho, bobo fofo" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
        end

        it "downcases suggested_tags" do
          post "/admin/config", params: { site_config: { suggested_tags: "hey, haha,hoHo, Bobo Fofo" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
        end

        it "removes space suggested_users" do
          post "/admin/config", params: {
            site_config: { suggested_users: "piglet, tigger,eeyore, Christopher Robin, kanga,roo" },
            confirmation: confirmation_message
          }
          expect(SiteConfig.suggested_users).to eq(%w[piglet tigger eeyore christopherrobin kanga roo])
        end

        it "downcases suggested_users" do
          post "/admin/config", params: {
            site_config: { suggested_users: "piglet, tigger,EEYORE, Christopher Robin, KANGA,RoO" },
            confirmation: confirmation_message
          }
          expect(SiteConfig.suggested_users).to eq(%w[piglet tigger eeyore christopherrobin kanga roo])
        end
      end

      describe "Rate Limits" do
        it "updates rate_limit_follow_count_daily" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_follow_count_daily: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_follow_count_daily).from(500).to(3)
        end

        it "updates rate_limit_comment_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_comment_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_comment_creation).from(9).to(3)
        end

        it "updates rate_limit_published_article_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_published_article_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_published_article_creation).from(9).to(3)
        end

        it "updates rate_limit_organization_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_organization_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_organization_creation).from(1).to(3)
        end

        it "updates rate_limit_image_upload" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_image_upload: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_image_upload).from(9).to(3)
        end

        it "updates rate_limit_email_recipient" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_email_recipient: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_email_recipient).from(5).to(3)
        end

        it "updates rate_limit_user_subscription_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_user_subscription_creation: 1 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_user_subscription_creation).from(3).to(1)
        end

        it "updates rate_limit_article_update" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_article_update: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_article_update).from(30).to(3)
        end

        it "updates rate_limit_user_update" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_user_update: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_user_update).from(5).to(3)
        end

        it "updates rate_limit_feedback_message_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_feedback_message_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_feedback_message_creation).from(5).to(3)
        end

        it "updates rate_limit_listing_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_listing_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_listing_creation).from(1).to(3)
        end

        it "updates rate_limit_reaction_creation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_reaction_creation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_reaction_creation).from(10).to(3)
        end

        it "updates rate_limit_send_email_confirmation" do
          expect do
            post "/admin/config", params: { site_config: { rate_limit_send_email_confirmation: 3 },
                                            confirmation: confirmation_message }
          end.to change(SiteConfig, :rate_limit_send_email_confirmation).from(2).to(3)
        end
      end

      describe "Social Media" do
        it "updates social_media_handles" do
          expected_handle = { "facebook" => "tpd", "github" => "", "instagram" => "", "twitch" => "", "twitter" => "" }
          post "/admin/config", params: { site_config: { social_media_handles: expected_handle },
                                          confirmation: confirmation_message }
          expect(SiteConfig.social_media_handles[:facebook]).to eq("tpd")
          expect(SiteConfig.social_media_handles[:github]).to eq("")
        end

        describe "twitter_hashtag" do
          twitter_hashtag = "#DEVCommunity"
          params = { site_config: { twitter_hashtag: twitter_hashtag }, confirmation: "Incorrect confirmation" }

          it "does not update the twitter hashtag without the correct confirmation text" do
            expect { post "/admin/config", params: params }.to raise_error ActionController::BadRequest
          end

          it "updates the twitter hashtag" do
            params["confirmation"] = confirmation_message
            post "/admin/config", params: params
            expect(SiteConfig.twitter_hashtag.to_s).to eq twitter_hashtag
          end
        end
      end

      describe "Sponsors" do
        it "updates the sponsor_headline" do
          headline = "basic"
          post "/admin/config", params: { site_config: { sponsor_headline: headline },
                                          confirmation: confirmation_message }
          expect(SiteConfig.sponsor_headline).to eq(headline)
        end
      end

      describe "Tags" do
        it "removes space sidebar_tags" do
          post "/admin/config", params: { site_config: { sidebar_tags: "hey, haha,hoho, bobo fofo" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.sidebar_tags).to eq(%w[hey haha hoho bobofofo])
        end

        it "downcases sidebar_tags" do
          post "/admin/config", params: { site_config: { sidebar_tags: "hey, haha,hoHo, Bobo Fofo" },
                                          confirmation: confirmation_message }
          expect(SiteConfig.sidebar_tags).to eq(%w[hey haha hoho bobofofo])
        end
      end

      describe "User Experience" do
        it "updates the feed_style" do
          feed_style = "basic"
          post "/admin/config", params: { site_config: { mascot_user_id: feed_style },
                                          confirmation: confirmation_message }
          expect(SiteConfig.feed_style).to eq(feed_style)
        end

        it "updates public to true" do
          is_public = true
          post "/admin/config", params: { site_config: { public: is_public },
                                          confirmation: confirmation_message }
          expect(SiteConfig.public).to eq(is_public)
        end

        it "updates public to false" do
          is_public = false
          post "/admin/config", params: { site_config: { public: is_public },
                                          confirmation: confirmation_message }
          expect(SiteConfig.public).to eq(is_public)
        end
      end

      describe "Credits" do
        it "updates the credit prices", :aggregate_failures do
          original_prices = {
            small: 500,
            medium: 400,
            large: 300,
            xlarge: 250
          }
          SiteConfig.credit_prices_in_cents = original_prices

          SiteConfig.credit_prices_in_cents.each_key do |size|
            new_prices = original_prices.merge(size => 123)
            expect do
              post "/admin/config", params: { site_config: { credit_prices_in_cents: new_prices },
                                              confirmation: confirmation_message }
            end.to change { SiteConfig.credit_prices_in_cents[size] }.from(original_prices[size.to_sym]).to(123)
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/NestedGroups
end
