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
        mod-status-#{user.admin? || !user.moderator_for_tags.empty?}
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "includes user role names in body class" do
      user.add_role(:tag_moderator)
      expected_result = %W[
        light-theme sans-serif-article-body
        mod-status-#{user.admin? || !user.moderator_for_tags.empty?}
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
        user-role--tag_moderator
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with sans serif config" do
      user.setting.config_font = "sans_serif"
      expected_result = %W[
        light-theme sans-serif-article-body
        mod-status-#{user.admin? || !user.moderator_for_tags.empty?}
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "creates proper body class with dark theme" do
      user.setting.config_theme = "dark_theme"
      expected_result = %W[
        dark-theme sans-serif-article-body
        mod-status-#{user.admin? || !user.moderator_for_tags.empty?}
        trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header
        ten-x-hacker-theme
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    it "works with static navbar" do
      user.setting.config_navbar = "static"
      expected_result = %W[
        light-theme sans-serif-article-body
        mod-status-#{user.admin? || !user.moderator_for_tags.empty?}
        trusted-status-#{user.trusted?} static-header
      ].join(" ")
      expect(user.decorate.config_body_class).to eq(expected_result)
    end

    context "when user with roles" do
      let(:user) { create(:user) }

      it "creates proper body class with trusted user" do
        user.add_role(:trusted)

        expected_result = %w[
          light-theme sans-serif-article-body mod-status-false
          trusted-status-true default-header user-role--trusted
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

  # START: Added tests for ordered_subforems
  describe "#ordered_subforems" do
    let(:decorated_user) { user.decorate }
    let(:activity_store) { instance_double("UserActivity") }

    # Create some subforems to work with
    let!(:sf1) { create(:subforem, domain: "#{rand(10000)}.com") }
    let!(:sf2) { create(:subforem, domain: "#{rand(10000)}.com") }
    let!(:sf3) { create(:subforem, domain: "#{rand(10000)}.com") }
    let!(:sf4) { create(:subforem, domain: "#{rand(10000)}.com") }
    let!(:sf5) { create(:subforem, domain: "#{rand(10000)}.com") }

    before do
      # Mock the user_activity call to return our test double
      allow(decorated_user).to receive(:user_activity).and_return(activity_store)
      
      # Mock the class method to get all discoverable subforems
      all_ids = [sf1.id, sf2.id, sf3.id, sf4.id, sf5.id]
      allow(Subforem).to receive(:cached_discoverable_ids).and_return(all_ids)
    end

    context "when user has recent and followed activity" do
      it "returns a properly weighted and sorted list of subforem IDs" do
        # sf1 score: 2 (recent) + 10 (followed) = 12
        # sf3 score: 1 (recent) = 1
        # sf2 score: 10 (followed) = 10
        # Expected user order: sf1, sf2, sf3
        # Expected final order: sf1, sf2, sf3, sf4, sf5
        allow(activity_store).to receive(:recent_subforems).and_return([sf1.id, sf1.id, sf3.id])
        allow(activity_store).to receive(:alltime_subforems).and_return([sf1.id, sf2.id])
        
        expected_order = [sf1.id, sf2.id, sf3.id, sf4.id, sf5.id]
        expect(decorated_user.ordered_subforems).to eq(expected_order)
      end
    end

    context "when user has only recent activity" do
      it "sorts by recent activity and appends the rest" do
        # sf2 score: 2
        # sf1 score: 1
        # Expected user order: sf2, sf1
        # Expected final order: sf2, sf1, sf3, sf4, sf5
        allow(activity_store).to receive(:recent_subforems).and_return([sf2.id, sf1.id, sf2.id])
        allow(activity_store).to receive(:alltime_subforems).and_return([])

        expected_order = [sf2.id, sf1.id, sf3.id, sf4.id, sf5.id]
        expect(decorated_user.ordered_subforems).to eq(expected_order)
      end
    end

    context "when user has no activity" do
      it "returns the default list of discoverable subforems" do
        allow(activity_store).to receive(:recent_subforems).and_return([])
        allow(activity_store).to receive(:alltime_subforems).and_return([])

        expected_order = [sf1.id, sf2.id, sf3.id, sf4.id, sf5.id]
        expect(decorated_user.ordered_subforems).to eq(expected_order)
      end
    end
    
    context "when activity store returns nil values" do
      it "compacts the arrays and calculates scores correctly" do
        # sf1 score: 1 (recent) + 10 (followed) = 11
        # sf2 score: 10 (followed) = 10
        # Expected user order: sf1, sf2
        # Expected final order: sf1, sf2, sf3, sf4, sf5
        allow(activity_store).to receive(:recent_subforems).and_return([sf1.id, nil])
        allow(activity_store).to receive(:alltime_subforems).and_return([sf2.id, nil, sf1.id])

        expected_order = [sf1.id, sf2.id, sf3.id, sf4.id, sf5.id]
        expect(decorated_user.ordered_subforems).to eq(expected_order)
      end
    end

    context "when there is no activity store" do
      it "returns an empty array" do
        allow(decorated_user).to receive(:user_activity).and_return(nil)
        expect(decorated_user.ordered_subforems).to eq([])
      end
    end
  end
  # END: Added tests
end