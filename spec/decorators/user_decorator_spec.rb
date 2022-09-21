require "rails_helper"

RSpec.describe UserDecorator, type: :decorator do
  let(:saved_user) { create(:user) }
  let(:user) { create(:user) }

  context "with serialization" do
    it "serializes both the decorated object IDs and decorated methods" do
      user = saved_user.decorate
      expected_result = { "id" => user.id }
      expect(user.as_json(only: [:id])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      user = saved_user.decorate
      decorated_collection = User.decorate
      expected_result = [{ "id" => user.id }]
      expect(decorated_collection.as_json(only: [:id])).to eq(expected_result)
    end
  end

  describe "#cached_followed_tags" do
    let(:saved_user) { create(:user) }
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }

    it "returns array of tags if user follows them" do
      _tag3 = create(:tag)
      saved_user.follow(tag1)
      saved_user.follow(tag2)

      results = saved_user.decorate.cached_followed_tags
      expect(results.size).to eq(2)
      expect(results.map(&:id).sort).to eq([tag1.id, tag2.id])
      expect(results.first.points).to eq(1)
    end
  end

  describe "#darker_color" do
    it "returns a darker version of the assigned color if colors are blank" do
      saved_user.setting.update(brand_color1: "")
      expect(saved_user.decorate.darker_color).to be_present
    end

    it "returns a darker version of the color if brand_color1 is present" do
      saved_user.setting.update(brand_color1: "#dddddd")
      expect(saved_user.decorate.darker_color).to eq("#c2c2c2")
    end

    it "returns an adjusted darker version of the color" do
      saved_user.setting.update(brand_color1: "#dddddd")
      expect(saved_user.decorate.darker_color(0.3)).to eq("#424242")
    end

    it "returns an adjusted lighter version of the color if adjustment is over 1.0" do
      saved_user.setting.update(brand_color1: "#dddddd")
      expect(saved_user.decorate.darker_color(1.1)).to eq("#f3f3f3")
    end
  end

  describe "#enriched_colors" do
    it "returns assigned colors if brand_color1 is blank" do
      saved_user.setting.update(brand_color1: "")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end

    it "returns brand_color1 if present" do
      saved_user.setting.update(brand_color1: "#dddddd")
      expect(saved_user.decorate.enriched_colors[:bg]).to be_present
      expect(saved_user.decorate.enriched_colors[:text]).to be_present
    end
  end

  describe "#config_body_class" do
    it "creates proper body class with defaults" do
      expected_result = %W[
        light-theme sans-serif-article-body
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with sans serif config" do
      user.setting.config_font = "sans_serif"
      expected_result = %W[
        light-theme sans-serif-article-body
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with dark theme" do
      user.setting.config_theme = "dark_theme"
      expected_result = %W[
        dark-theme sans-serif-article-body
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "works with static navbar" do
      user.setting.config_navbar = "static"
      expected_result = %W[
        light-theme sans-serif-article-body
        trusted-status-#{user.trusted?} static-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    context "when user with roles" do
      let(:user) { create(:user) }

      it "creates proper body class with trusted user" do
        user.add_role(:trusted)

        expected_result = %w[
          light-theme sans-serif-article-body
          trusted-status-true default-header
        ].join(" ")
        expect(user.decorate.config_body_class).to eq(expected_result)
      end
    end
  end

  describe "#fully_banished?" do
    it "returns not fully banished if in good standing" do
      expect(user.decorate.fully_banished?).to be(false)
    end

    it "returns fully banished if user has been banished" do
      Moderator::BanishUser.call(admin: user, user: user)
      expect(user.decorate.fully_banished?).to be(true)
    end
  end

  describe "#considered_new?" do
    let(:decorated_user) { user.decorate }

    it "delegates to Settings::RateLimit.considered_new?" do
      allow(Settings::RateLimit).to receive(:user_considered_new?).with(user: decorated_user).and_return(true)
      expect(decorated_user.considered_new?).to be(true)
      expect(Settings::RateLimit).to have_received(:user_considered_new?).with(user: decorated_user)
    end
  end
end
