require "rails_helper"

RSpec.describe "/internal/config", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :super_admin) }

  describe "POST internal/events as a user" do
    before do
      sign_in(user)
    end

    it "bars the regular user to access" do
      expect { post "/internal/config", params: {} }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST internal/events" do
    before do
      sign_in(admin)
    end

    describe "staff" do
      it "updates staff_user_id" do
        post "/internal/config", params: { site_config: { staff_user_id: 2 } }
        expect(SiteConfig.staff_user_id).to eq(2)
      end

      it "updates default_site_email" do
        expected_email = "foo@bar.com"
        post "/internal/config", params: { site_config: { default_site_email: expected_email } }
        expect(SiteConfig.default_site_email).to eq(expected_email)
      end

      it "updates social_networks_handle" do
        expected_handle = "tpd"
        post "/internal/config", params: { site_config: { social_networks_handle: expected_handle } }
        expect(SiteConfig.social_networks_handle).to eq(expected_handle)
      end
    end

    describe "images" do
      it "updates main_social_image" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { main_social_image: expected_image_url } }
        expect(SiteConfig.main_social_image).to eq(expected_image_url)
      end

      it "updates favicon_url" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { favicon_url: expected_image_url } }
        expect(SiteConfig.favicon_url).to eq(expected_image_url)
      end

      it "updates logo_svg" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { logo_svg: expected_image_url } }
        expect(SiteConfig.logo_svg).to eq(expected_image_url)
      end
    end

    describe "rate limits" do
      it "updates rate_limit_follow_count_daily" do
        expect do
          post "/internal/config", params: { site_config: { rate_limit_follow_count_daily: 3 } }
        end.to change(SiteConfig, :rate_limit_follow_count_daily).from(500).to(3)
      end

      it "updates rate_limit_comment_creation" do
        expect do
          post "/internal/config", params: { site_config: { rate_limit_comment_creation: 3 } }
        end.to change(SiteConfig, :rate_limit_comment_creation).from(9).to(3)
      end

      it "updates rate_limit_published_article_creation" do
        expect do
          post "/internal/config", params: { site_config: { rate_limit_published_article_creation: 3 } }
        end.to change(SiteConfig, :rate_limit_published_article_creation).from(9).to(3)
      end

      it "updates rate_limit_image_upload" do
        expect do
          post "/internal/config", params: { site_config: { rate_limit_image_upload: 3 } }
        end.to change(SiteConfig, :rate_limit_image_upload).from(9).to(3)
      end

      it "updates rate_limit_email_recipient" do
        expect do
          post "/internal/config", params: { site_config: { rate_limit_email_recipient: 3 } }
        end.to change(SiteConfig, :rate_limit_email_recipient).from(5).to(3)
      end
    end

    describe "Google Analytics Reporting API v4" do
      it "updates ga_view_id" do
        post "/internal/config", params: { site_config: { ga_view_id: "abc" } }
        expect(SiteConfig.ga_view_id).to eq("abc")
      end

      it "updates ga_fetch_rate" do
        post "/internal/config", params: { site_config: { ga_fetch_rate: 3 } }
        expect(SiteConfig.ga_fetch_rate).to eq(3)
      end
    end

    describe "Mailchimp lists IDs" do
      it "updates mailchimp_newsletter_id" do
        post "/internal/config", params: { site_config: { mailchimp_newsletter_id: "abc" } }
        expect(SiteConfig.mailchimp_newsletter_id).to eq("abc")
      end

      it "updates mailchimp_sustaining_members_id" do
        post "/internal/config", params: { site_config: { mailchimp_sustaining_members_id: "abc" } }
        expect(SiteConfig.mailchimp_sustaining_members_id).to eq("abc")
      end

      it "updates mailchimp_tag_moderators_id" do
        post "/internal/config", params: { site_config: { mailchimp_tag_moderators_id: "abc" } }
        expect(SiteConfig.mailchimp_tag_moderators_id).to eq("abc")
      end

      it "updates mailchimp_community_moderators_id" do
        post "/internal/config", params: { site_config: { mailchimp_community_moderators_id: "abc" } }
        expect(SiteConfig.mailchimp_community_moderators_id).to eq("abc")
      end
    end

    describe "Email digest frequency" do
      it "updates periodic_email_digest_max" do
        post "/internal/config", params: { site_config: { periodic_email_digest_max: 1 } }
        expect(SiteConfig.periodic_email_digest_max).to eq(1)
      end

      it "updates periodic_email_digest_min" do
        post "/internal/config", params: { site_config: { periodic_email_digest_min: 3 } }
        expect(SiteConfig.periodic_email_digest_min).to eq(3)
      end
    end

    describe "Tags" do
      it "removes space suggested_tags" do
        post "/internal/config", params: { site_config: { suggested_tags: "hey, haha,hoho, bobo fofo" } }
        expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
      end

      it "downcases suggested_tags" do
        post "/internal/config", params: { site_config: { suggested_tags: "hey, haha,hoHo, Bobo Fofo" } }
        expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
      end
    end
  end
end
