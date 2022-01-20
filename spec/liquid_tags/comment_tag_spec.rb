require "rails_helper"

RSpec.describe CommentTag, type: :liquid_tag do
  let(:user) { create(:user, name: "TheUser") }
  let(:article) { create(:article) }
  let(:comment) do
    create(:comment, commentable: article, user: user, body_markdown: "TheComment")
  end

  before { Liquid::Template.register_tag("comment", described_class) }

  def generate_comment_tag(id_code)
    Liquid::Template.parse("{% comment #{id_code} %}")
  end

  context "when given valid id_code" do
    it "fetches the target comment and render properly" do
      liquid = generate_comment_tag(comment.id_code_generated)

      expect(liquid.render).to include(comment.body_markdown)
        .and include(user.name)
    end

    it "renders 'Comment Not Found' message if comment ID does not exist" do
      liquid = generate_comment_tag("nonexistentid")

      expect(liquid.render).to include("Comment Not Found")
    end
  end

  context "when rendered" do
    let(:rendered_tag) { generate_comment_tag(comment.id_code_generated).render }

    it "shows the comment date" do
      expect(rendered_tag).to include(comment.readable_publish_date)
    end

    it "embeds the comment published timestamp" do
      expect(rendered_tag).to include(comment.decorate.published_timestamp)
    end
  end

  context "with the legacy 'devcomment'" do
    before do
      Liquid::Template.register_tag("devcomment", described_class)
    end

    it "renders properly" do
      liquid = Liquid::Template.parse("{% devcomment #{comment.id_code_generated} %}")

      expect(liquid.render).to include(comment.body_markdown)
      expect(liquid.render).to include(user.name)
    end
  end

  context "when given invalid id_code" do
    it "raises an error" do
      expect do
        generate_comment_tag("Invalid%ID").render
      end.to raise_error(StandardError, "Invalid Comment ID or URL")
    end
  end
end
