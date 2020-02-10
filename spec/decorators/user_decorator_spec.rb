require "rails_helper"

RSpec.describe UserDecorator, type: :decorator do
  let(:user) { build_stubbed(:user) }

  describe "#cached_followed_tags" do
    let_it_be(:user) { create(:user) }
    let(:tag1)  { create(:tag) }
    let(:tag2)  { create(:tag) }
    let(:tag3)  { create(:tag) }

    it "returns empty if no tags followed" do
      expect(user.decorate.cached_followed_tags.size).to eq(0)
    end

    it "returns array of tags if user follows them" do
      user.follow(tag1)
      user.follow(tag2)
      user.follow(tag3)
      expect(user.decorate.cached_followed_tags.size).to eq(3)
    end

    it "returns tag object with name" do
      user.follow(tag1)
      expect(user.decorate.cached_followed_tags.first.name).to eq(tag1.name)
    end

    it "returns follow points for tag" do
      user.follow(tag1)
      expect(user.decorate.cached_followed_tags.first.points).to eq(1.0)
    end

    it "returns adjusted points for tag" do
      follow = user.follow(tag1)
      follow.update(points: 0.1)
      expect(user.decorate.cached_followed_tags.first.points).to eq(0.1)
    end

    it "returns not fully banished if in good standing" do
      expect(user.decorate.fully_banished?).to eq(false)
    end

    it "returns fully banished if user has been banished" do
      Moderator::BanishUser.call(admin: user, user: user)
      expect(user.decorate.fully_banished?).to eq(true)
    end
  end

  describe "#config_body_class" do
    it "creates proper body class with defaults" do
      expected_result = %W[
        default default-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} #{user.config_navbar}-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with sans serif config" do
      user.config_font = "sans_serif"
      expected_result = %W[
        default sans-serif-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} #{user.config_navbar}-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with night theme" do
      user.config_theme = "night_theme"
      expected_result = %W[
        night-theme default-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} #{user.config_navbar}-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with pink theme" do
      user.config_theme = "pink_theme"
      expected_result = %W[
        pink-theme default-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} #{user.config_navbar}-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with minimal light theme" do
      user.config_theme = "minimal_light_theme"
      expected_result = %W[
        minimal-light-theme default-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} #{user.config_navbar}-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "works with static navbar" do
      user.config_navbar = "static"
      expected_result = %W[
        default default-article-body pro-status-#{user.pro?}
        trusted-status-#{user.trusted} static-navbar-config
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    context "when user with roles" do
      let(:user) { create(:user) }

      it "creates proper body class with pro user" do
        user.add_role(:pro)

        expected_result = %W[
          default default-article-body pro-status-true
          trusted-status-#{user.trusted} default-navbar-config
        ].join(" ")
        expect(user.decorate.config_body_class).to eq(expected_result)
      end

      it "creates proper body class with trusted user" do
        user.add_role(:trusted)

        expected_result = %W[
          default default-article-body pro-status-#{user.pro?}
          trusted-status-true default-navbar-config
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
end
