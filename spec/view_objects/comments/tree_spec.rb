require "rails_helper"

RSpec.describe Comments::Tree do
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:child_comment) { create(:comment, commentable: article, parent: comment) }
  let!(:grandchild_comment) { create(:comment, commentable: article, parent: child_comment) }

  let(:sub_comments) { { child_comment => { grandchild_comment => {} } } }

  it "shows comments" do
    context = ActionView::Base.new(Rails.root.join("app", "views"), {})
    context.class_eval { include CommentsHelper }

    html = described_class.new(context: context, comment: comment, sub_comments: sub_comments, commentable: article).display

    expect(html).to include(comment.processed_html)
    expect(html).to include(child_comment.processed_html)
    expect(html).to include(grandchild_comment.processed_html)
  end
end
