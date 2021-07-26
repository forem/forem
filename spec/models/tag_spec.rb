require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  describe "validations" do
    describe "builtin validations" do
      subject { tag }

      it { is_expected.to belong_to(:badge).optional }
      it { is_expected.to have_one(:sponsorship).inverse_of(:sponsorable).dependent(:destroy) }

      it { is_expected.to validate_length_of(:name).is_at_most(30) }
      it { is_expected.to validate_presence_of(:category) }

      it { is_expected.not_to allow_value("#Hello", "c++", "AWS-Lambda").for(:name) }

      # rubocop:disable RSpec/NamedSubject
      it do
        expect(subject).to belong_to(:mod_chat_channel)
          .class_name("ChatChannel")
          .optional
      end

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

      it "fails validations if name uses non-ASCII characters" do
        tag.name = "مرحبا"
        expect(tag).not_to be_valid

        tag.name = "你好"
        expect(tag).not_to be_valid

        tag.name = "Cześć"
        expect(tag).not_to be_valid

        tag.name = "♩ ♪ ♫ ♬ ♭ ♮ ♯"
        expect(tag).not_to be_valid

        tag.name = "Test™"
        expect(tag).not_to be_valid
      end
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

  it "triggers articles cache busting on save" do
    sidekiq_perform_enqueued_jobs do
      tag.save
    end
    first = create(:article, tags: tag.name, published: true)
    second = create(:article, tags: tag.name, published: true)
    sidekiq_assert_enqueued_with(job: Articles::BustMultipleCachesWorker, args: [[second.id, first.id]]) do
      tag.save
    end
  end

  it "finds mod chat channel" do
    channel = create(:chat_channel)
    tag.mod_chat_channel_id = channel.id
    expect(tag.mod_chat_channel).to eq(channel)
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
end
