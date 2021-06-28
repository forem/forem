require "rails_helper"

RSpec.describe Articles::Builder, type: :service do
  let(:user) { create(:user) }
  let(:tag) { nil }
  let(:prefill) { nil }

  context "when tag_user_editor_v2" do
    let(:user) { create(:user) }
    let(:tag) { create(:tag) }
    let(:submission_template) { tag.submission_template_customized(user.name).to_s }
    let(:correct_attributes) do
      {
        body_markdown: submission_template.split("---").last.to_s.strip,
        cached_tag_list: tag.name,
        processed_html: "",
        user_id: user.id,
        title: submission_template.split("title:")[1].to_s.split("\n")[0].to_s.strip
      }
    end

    it "initializes an article with the correct attributes and needs authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be true
    end
  end

  context "when tag_user" do
    let(:tag) { create(:tag, submission_template: "submission_template") }
    let(:correct_attributes) do
      {
        body_markdown: tag.submission_template_customized(user.name),
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes and needs authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be true
    end
  end

  context "when prefill_user_editor_v2" do
    let(:user) { create(:user) }
    let(:prefill) { "dsdweewewew" }
    let(:correct_attributes) do
      {
        body_markdown: prefill.split("---").last.to_s.strip,
        cached_tag_list: prefill.split("tags:")[1].to_s.split("\n")[0].to_s.strip,
        processed_html: "",
        user_id: user.id,
        title: prefill.split("title:")[1].to_s.split("\n")[0].to_s.strip
      }
    end

    it "initializes an article with the correct attributesand needs authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be true
    end
  end

  context "when prefill_user" do
    let(:prefill) { "dsdweewewew" }
    let(:correct_attributes) do
      {
        body_markdown: prefill,
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes and needs authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be true
    end
  end

  context "when tag" do
    let(:user) { create(:user, editor_version: "v1") }
    let(:tag) { create(:tag) }
    let(:correct_attributes) do
      {
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{tag.name}\n---\n\n",
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes and does not need authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be false
    end
  end

  context "when user_editor_v2" do
    let(:user) { create(:user) }
    let(:correct_attributes) do
      {
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes and does not need authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be false
    end
  end

  context "when user_editor_v1" do
    let(:user) { create(:user, editor_version: "v1") }
    let(:correct_attributes) do
      body = "---\ntitle: \npublished: false\ndescription: \ntags: " \
        "\n//cover_image: https://direct_url_to_image.jpg\n---\n\n"

      {
        body_markdown: body,
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes and does not need authorization" do
      subject, needs_authorization = described_class.call(user, tag, prefill)

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
      expect(needs_authorization).to be false
    end
  end
end
