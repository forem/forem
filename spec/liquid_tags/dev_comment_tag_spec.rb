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
    it "renders properly fails because of timestamp", skip: "approvals gem does not have configuration to handle dynamically generated values" do
      liquid = generate_comment_tag(comment.id_code_generated)
      verify format: :html do
        liquid.render
      end
      # Above test will not pass because comments has dynamically changing values (timestamp) and the Approvals gem does not have a configuration exclude it
    end

    it "raise error if comment does not exist" do
      expect do
        liquid = generate_comment_tag("this will fail")
        liquid.render
      end.to raise_error(StandardError)
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
