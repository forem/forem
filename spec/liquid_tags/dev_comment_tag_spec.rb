require "rails_helper"

RSpec.describe DevCommentTag, type: :liquid_template do
  let(:user) { create(:user, username: "DevCommentTagTest", name: "DevCommentTag Test") }
  let(:article)     { create(:article) }
  let(:comment)     { create(:comment, commentable: article, body_markdown: "DevCommentTagTest", user: user) }

  setup             { Liquid::Template.register_tag("devcomment", DevCommentTag) }

  def generate_comment_tag(id_code)
    Liquid::Template.parse("{% devcomment #{id_code} %}")
  end

  it "renders properly" do
    liquid = generate_comment_tag(comment.id_code_generated)
    # Approvals.verify(liquid.render, format: :html)
    verify format: :html do
      liquid.render
    end
  end

  it "raise error if comment does not exist" do
    liquid = generate_comment_tag("this should fail")
    liquid.render
    expect(liquid.errors).not_to be_empty
  end
end
