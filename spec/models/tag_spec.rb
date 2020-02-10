require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  it { is_expected.to validate_length_of(:name).is_at_most(30) }
  it { is_expected.not_to allow_value("#Hello", "c++", "AWS-Lambda").for(:name) }

  describe "validations" do
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

      it "fails validations if name is not alphanumeric" do
        tag.name = ""
        expect(tag).not_to be_valid
      end
    end

    it "fails validation if the alias does not refer to an existing tag" do
      tag.alias_for = "hello"
      expect(tag).not_to be_valid
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

  it "finds mod chat channel" do
    channel = create(:chat_channel)
    tag.mod_chat_channel_id = channel.id
    expect(tag.mod_chat_channel).to eq(channel)
  end
end
