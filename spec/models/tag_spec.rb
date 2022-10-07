require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  describe "#class_name" do
    subject(:class_name) { tag.class_name }

    it { is_expected.to eq("Tag") }
  end

  describe "validations" do
    describe "builtin validations" do
      subject { tag }

      it { is_expected.to belong_to(:badge).optional }
      it { is_expected.to validate_length_of(:name).is_at_most(30) }
      it { is_expected.to validate_presence_of(:category) }

      it { is_expected.not_to allow_value("#Hello", "c++", "AWS-Lambda").for(:name) }

      # rubocop:disable RSpec/NamedSubject
      it do
        expect(subject).to validate_inclusion_of(:category)
          .in_array(%w[uncategorized language library tool site_mechanic location subcommunity])
      end
      # rubocop:enable RSpec/NamedSubject
    end

    describe "bg_color_hex" do
      it "passes validations if bg_color_hex is valid" do
        tag.bg_color_hex = "#000000"
        expect(tag).to be_valid
      end

      it "fails validation if bg_color_hex is invalid" do
        tag.bg_color_hex = "0000000"
        expect(tag).not_to be_valid
      end
    end

    describe "text_color_hex" do
      it "passes validations if text_color_hex is valid" do
        tag.text_color_hex = "#000000"
        expect(tag).to be_valid
      end

      it "fails validation if text_color_hex is invalid" do
        tag.text_color_hex = "0000000"
        expect(tag).not_to be_valid
      end
    end

    describe "name" do
      it "passes validations if name is alphanumeric" do
        tag.name = "foobar123"
        expect(tag).to be_valid
      end

      it "fails validations if name is empty" do
        tag.name = ""
        expect(tag).not_to be_valid
      end

      it "fails validations if name is nil" do
        tag.name = nil
        expect(tag).not_to be_valid
      end

      it "validates name is alphanumeric characters" do
        # arabic is allowed
        tag.name = "مرحبا"
        expect(tag).to be_valid

        # chinese is allowed
        tag.name = "你好"
        expect(tag).to be_valid

        # Polish characters are allowed
        tag.name = "Cześć"
        expect(tag).to be_valid

        # musical notes are not :alnum:
        tag.name = "♩ ♪ ♫ ♬ ♭ ♮ ♯"
        expect(tag).not_to be_valid

        # ™ is not :alnum:
        tag.name = "Test™"
        expect(tag).not_to be_valid
      end
    end

    it "fails validation if name is a prohibited (whitespace) unicode character" do
      tag.name = "U+202D"
      expect(tag).not_to be_valid
    end

    describe "alias_for" do
      it "passes validation if the alias refers to an existing tag" do
        tag = create(:tag)
        tag.alias_for = tag.name
        expect(tag).to be_valid
      end

      it "fails validation if the alias does not refer to an existing tag" do
        tag.alias_for = "hello"
        expect(tag).not_to be_valid
      end
    end
  end

  it "strips HTML tags from short_summary before saving" do
    tag.short_summary = "<p>Hello <strong>World</strong>.</p>"
    tag.save
    expect(tag.short_summary).to eq("Hello World.")
  end

  it "turns markdown into HTML before saving" do
    tag.rules_markdown = "Hello [Google](https://google.com)"
    tag.save
    expect(tag.rules_html.include?("href")).to be(true)
  end

  it "marks as updated after save" do
    tag.save
    expect(tag.reload.updated_at).to be > 1.minute.ago
  end

  it "knows class valid categories" do
    expect(described_class.valid_categories).to include("tool")
  end

  it "triggers cache busting on save" do
    sidekiq_assert_enqueued_with(job: Tags::BustCacheWorker, args: [tag.name]) do
      tag.save
    end
  end

  it "delete tag-colors server cache on save" do
    allow(Rails.cache).to receive(:delete)
    tag.save
    expect(Rails.cache).to have_received(:delete).with("view-helper-#{tag.name}/tag_colors")
  end

  describe "::aliased_name" do
    it "returns the preferred alias tag" do
      preferred_tag = create(:tag, name: "rails")
      bad_tag = create(:tag, name: "ror", alias_for: "rails")
      expect(described_class.aliased_name(bad_tag.name)).to eq(preferred_tag.name)
    end

    it "returns self if there's no preferred alias" do
      tag = create(:tag, name: "ror")
      expect(described_class.aliased_name(tag.name)).to eq(tag.name)
    end

    it "returns nil for non-existing tag" do
      expect(described_class.aliased_name("faketag")).to be_nil
    end
  end

  describe "::find_preferred_alias_for" do
    it "returns preferred tag" do
      preferred_tag = create(:tag, name: "rails")
      tag = create(:tag, name: "ror", alias_for: "rails")
      expect(described_class.find_preferred_alias_for(tag.name)).to eq(preferred_tag.name)
    end

    it "returns self if there's no preferred tag" do
      expect(described_class.find_preferred_alias_for("something")).to eq("something")
    end
  end

  describe ".followed_tags_for" do
    let(:saved_user) { create(:user) }
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:tag3) { create(:tag) }

    it "returns empty if no tags followed" do
      expect(described_class.followed_tags_for(follower: saved_user).size).to eq(0)
    end

    it "returns array of tags if user follows them" do
      saved_user.follow(tag1)
      saved_user.follow(tag2)
      saved_user.follow(tag3)
      expect(described_class.followed_tags_for(follower: saved_user).size).to eq(3)
    end

    it "returns tag object with name" do
      saved_user.follow(tag1)
      expect(described_class.followed_tags_for(follower: saved_user).first.name).to eq(tag1.name)
    end

    it "returns follow points for tag" do
      saved_user.follow(tag1)
      expect(described_class.followed_tags_for(follower: saved_user).first.points).to eq(1.0)
    end

    it "returns adjusted points for tag" do
      follow = saved_user.follow(tag1)
      follow.update(explicit_points: 0.1)

      expect(described_class.followed_tags_for(follower: saved_user).first.points).to eq(0.1)
    end
  end

  describe "#points" do
    it "defaults to 0" do
      expect(described_class.new.points).to eq(0)
    end
  end

  # [@jeremyf] The implementation details of #accessible_name are contingent on a feature flag that
  #            we're using for this refactoring.  Once we remove the flag, please adjust the specs
  #            accordingly.
  describe "#accessible_name" do
    subject(:accessible_name) { described_class.new(name: name, pretty_name: pretty_name).accessible_name }

    let(:name) { "helloworld" }
    let(:pretty_name) { "helloWorld" }

    context "when favor_accessible_name_for_tag_label is true" do
      before { allow(described_class).to receive(:favor_accessible_name_for_tag_label?).and_return(true) }

      it "equals the #pretty_name" do
        expect(accessible_name).to eq pretty_name
      end
    end

    context "when favor_accessible_name_for_tag_label is true but no pretty name given" do
      before { allow(described_class).to receive(:favor_accessible_name_for_tag_label?).and_return(true) }

      let(:pretty_name) { nil }

      it "equals the #name" do
        expect(accessible_name).to eq name
      end
    end

    context "when favor_accessible_name_for_tag_label is false" do
      before { allow(described_class).to receive(:favor_accessible_name_for_tag_label?).and_return(false) }

      it "equals the #name" do
        expect(accessible_name).to eq name
      end
    end
  end
end
