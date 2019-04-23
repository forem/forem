require "rails_helper"

RSpec.describe DevCommentTag, type: :liquid_template do
  let(:user)        { create(:user, username: "DevCommentTagTest", name: "DevCommentTag Test") }
  let(:article)     { create(:article) }
  let(:comment)     { create(:comment, commentable: article, body_markdown: "DevCommentTagTest", user: user) }

  setup             { Liquid::Template.register_tag("devcomment", DevCommentTag) }

  def generate_comment_tag(id_code)
    Liquid::Template.parse("{% devcomment #{id_code} %}")
  end

  context "when given valid id_code" do
    it "renders properly" do
      liquid = generate_comment_tag(comment.id_code_generated)
      Approvals.verify(liquid.render, format: :html)
      verify format: :html do
        liquid.render
      end
    end

    it "raise error if comment does not exist" do
      liquid = generate_comment_tag("this will fail")
      liquid.render
      expect(liquid.error).not_to_be_empty
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
end
