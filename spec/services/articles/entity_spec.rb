require "rails_helper"

RSpec.describe Articles::Entity, type: :service do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:prefill) { "dsdweewewew" }
  let(:article) { described_class.new(user.id, user.name, tag, prefill) }

  describe "tag_user_editor_v2" do
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

    it "initializes an article with the correct attributes" do
      subject = article.tag_user_editor_v2

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "tag_user" do
    let(:correct_attributes) do
      {
        body_markdown: tag.submission_template_customized(user.name),
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.tag_user

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "prefill_user_editor_v2" do
    let(:correct_attributes) do
      {
        body_markdown: prefill.split("---").last.to_s.strip,
        cached_tag_list: prefill.split("tags:")[1].to_s.split("\n")[0].to_s.strip,
        processed_html: "",
        user_id: user.id,
        title: prefill.split("title:")[1].to_s.split("\n")[0].to_s.strip
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.prefill_user_editor_v2

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "prefill_user" do
    let(:correct_attributes) do
      {
        body_markdown: prefill,
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.prefill_user

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "tag" do
    let(:correct_attributes) do
      {
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{tag.name}\n---\n\n",
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.tag

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "user_editor_v2" do
    let(:correct_attributes) do
      {
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.user_editor_v2

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end

  describe "user_editor_v1" do
    let(:correct_attributes) do
      {
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: \n---\n\n",
        processed_html: "",
        user_id: user.id
      }
    end

    it "initializes an article with the correct attributes" do
      subject = article.user_editor_v1

      expect(subject).to be_an_instance_of(Article)
      expect(subject).to have_attributes(correct_attributes)
    end
  end
end
