require "rails_helper"

RSpec.describe UserDecorator, type: :decorator do
  let(:saved_user) { create(:user) }
  let(:user) { build(:user) }

  context "with serialization" do
    it "serializes both the decorated object IDs and decorated methods" do
      user = saved_user.decorate
      expected_result = { "id" => user.id, "dark_theme?" => user.dark_theme? }
      expect(user.as_json(only: [:id], methods: [:dark_theme?])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      user = saved_user.decorate
      decorated_collection = User.decorate
      expected_result = [{ "id" => user.id, "dark_theme?" => user.dark_theme? }]
      expect(decorated_collection.as_json(only: [:id], methods: [:dark_theme?])).to eq(expected_result)
    end
  end

  describe "#cached_followed_tags" do
    let(:tag1)  { create(:tag) }
    let(:tag2)  { create(:tag) }
    let(:tag3)  { create(:tag) }

    it "returns empty if no tags followed" do
      expect(saved_user.decorate.cached_followed_tags.size).to eq(0)
    end

    it "returns array of tags if user follows them" do
      saved_user.follow(tag1)
      saved_user.follow(tag2)
      saved_user.follow(tag3)
      expect(saved_user.decorate.cached_followed_tags.size).to eq(3)
    end

    it "returns tag object with name" do
      saved_user.follow(tag1)
      expect(saved_user.decorate.cached_followed_tags.first.name).to eq(tag1.name)
    end

    it "returns follow points for tag" do
      saved_user.follow(tag1)
      expect(saved_user.decorate.cached_followed_tags.first.points).to eq(1.0)
    end

    it "returns adjusted points for tag" do
      follow = saved_user.follow(tag1)
      follow.update(explicit_points: 0.1)
      expect(saved_user.decorate.cached_followed_tags.first.points).to eq(0.1)
    end
  end

  describe "#darker_color" do
    it "returns a darker version of the assigned color if colors are blank" do
      saved_user.assign_attributes(bg_color_hex: "", text_color_hex: "")
      expect(saved_user.decorate.darker_color).to be_present
    end

    it "returns a darker version of the color if bg_color_hex is present" do
      saved_user.assign_attributes(bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(saved_user.decorate.darker_color).to eq("#c2c2c2")
    end

    it "returns an adjusted darker version of the color" do
      saved_user.assign_attributes(bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(saved_user.decorate.darker_color(0.3)).to eq("#424242")
    end

    it "returns an adjusted lighter version of the color if adjustment is over 1.0" do
      saved_user.assign_attributes(bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(saved_user.decorate.darker_color(1.1)).to eq("#f3f3f3")
    end
  end

  describe "#enriched_colors" do
    it "returns assigned colors if bg_color_hex is blank" do
      saved_user.assign_attributes(bg_color_hex: "")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end

    it "returns assigned colors if text_color_hex is blank" do
      saved_user.assign_attributes(text_color_hex: "")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end

    it "returns bg_color_hex and assigned text_color_hex if text_color_hex is blank" do
      saved_user.assign_attributes(bg_color_hex: "#dddddd", text_color_hex: "")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end

    it "returns text_color_hex and assigned bg_color_hex if bg_color_hex is blank" do
      saved_user.assign_attributes(bg_color_hex: "", text_color_hex: "#ffffff")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end

    it "returns bg_color_hex and text_color_hex if both are present" do
      saved_user.assign_attributes(bg_color_hex: "#dddddd", text_color_hex: "#fffff3")
      expect(saved_user.decorate.enriched_colors).to eq(bg: "#dddddd", text: "#fffff3")
    end
  end

  describe "#config_font_name" do
    it "replaces 'default' with font configured for the site in SiteConfig" do
      expect(user.config_font).to eq("default")
      %w[sans_serif serif open_dyslexic].each do |font|
        allow(Settings::UserExperience).to receive(:default_font).and_return(font)
        expect(user.decorate.config_font_name).to eq(font)
      end
    end

    it "doesn't replace the user's custom selected font" do
      user_comic_sans = create(:user, config_font: "comic_sans")
      allow(Settings::UserExperience).to receive(:default_font).and_return("open_dyslexic")
      expect(user_comic_sans.decorate.config_font_name).to eq("comic_sans")
    end
  end

  describe "#config_body_class" do
    it "creates proper body class with defaults" do
      expected_result = %W[
        default sans-serif-article-body
        trusted-status-#{user.trusted} #{user.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with sans serif config" do
      user.config_font = "sans_serif"
      expected_result = %W[
        default sans-serif-article-body
        trusted-status-#{user.trusted} #{user.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with night theme" do
      user.config_theme = "night_theme"
      expected_result = %W[
        night-theme sans-serif-article-body
        trusted-status-#{user.trusted} #{user.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with pink theme" do
      user.config_theme = "pink_theme"
      expected_result = %W[
        pink-theme sans-serif-article-body
        trusted-status-#{user.trusted} #{user.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with minimal light theme" do
      user.config_theme = "minimal_light_theme"
      expected_result = %W[
        minimal-light-theme sans-serif-article-body
        trusted-status-#{user.trusted} #{user.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "works with static navbar" do
      user.config_navbar = "static"
      expected_result = %W[
        default sans-serif-article-body
        trusted-status-#{user.trusted} static-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    context "when user with roles" do
      let(:user) { create(:user) }

      it "creates proper body class with trusted user" do
        user.add_role(:trusted)

        expected_result = %w[
          default sans-serif-article-body
          trusted-status-true default-header
        ].join(" ")
        expect(user.decorate.config_body_class).to eq(expected_result)
      end
    end
  end

  describe "#dark_theme?" do
    it "determines dark theme if night theme" do
      user.config_theme = "night_theme"
      expect(user.decorate.dark_theme?).to be(true)
    end

    it "determines dark theme if ten x hacker" do
      user.config_theme = "ten_x_hacker_theme"
      expect(user.decorate.dark_theme?).to be(true)
    end

    it "determines not dark theme if not one of the dark themes" do
      user.config_theme = "default"
      expect(user.decorate.dark_theme?).to be(false)
    end
  end

  describe "#fully_banished?" do
    it "returns not fully banished if in good standing" do
      expect(user.decorate.fully_banished?).to eq(false)
    end

    it "returns fully banished if user has been banished" do
      Moderator::BanishUser.call(admin: user, user: user)
      expect(user.decorate.fully_banished?).to eq(true)
    end
  end

  describe "#stackbit_integration?" do
    it "returns false by default" do
      expect(user.decorate.stackbit_integration?).to be(false)
    end

    it "returns true if the user has access tokens" do
      user.access_tokens.build
      expect(user.decorate.stackbit_integration?).to be(true)
    end
  end

  describe "#considered_new?" do
    before do
      allow(SiteConfig).to receive(:user_considered_new_days).and_return(3)
    end

    it "returns true for new users" do
      user.created_at = 1.day.ago
      expect(user.decorate.considered_new?).to be(true)
    end

    it "returns false for new users" do
      user.created_at = 1.year.ago
      expect(user.decorate.considered_new?).to be(false)
    end
  end
end
