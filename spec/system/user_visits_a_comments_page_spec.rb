require "rails_helper"

RSpec.describe "Views an article" do
  let(:user) { create(:user) }
  let(:co_author) { create(:user) }
  let(:commenter) { create(:user) }
  let(:article) do
    create(:article, user: user, co_author_ids: [co_author.id], with_tags: false, with_main_image: false)
  end
  let(:ama_article) { create(:article, user: user, tags: "ama", with_main_image: false) }

  let(:comment) { create(:comment, user: commenter, commentable: article) }
  let(:child_comment) { create(:comment, user: commenter, parent: comment, commentable: article) }

  it "shows all comments, op markers on author and co-author comments, and a single thread", :aggregate_failures do
    child_comment
    author_comment = create(:comment, user: user, commentable: article)
    co_author_comment = create(:comment, user: co_author, commentable: article)
    visit "#{article.path}/comments"

    expect(page).to have_css(".single-comment-node", visible: :visible, count: 4)
    expect(page).to have_no_css("#comment-node-#{comment.id} .spec-op-author")
    [author_comment, co_author_comment].each do |op_comment|
      expect(page).to have_css("#comment-node-#{op_comment.id} .spec-op-author[data-tooltip='Author']", count: 2)
    end

    visit "#{article.path}/comments/#{comment.id_code_generated}"

    expect(page).to have_css(".single-comment-node", visible: :visible, count: 2)
    expect(page).to have_css(".comment--deep-0#comment-node-#{comment.id}", visible: :visible, count: 1)
    expect(page).to have_css(".comment--deep-1#comment-node-#{child_comment.id}", visible: :visible, count: 1)
  end

  it "shows special op marker on ama articles" do
    ama_comment = create(:comment, user: user, commentable: ama_article)
    visit "#{ama_article.path}/comments"

    expect(page).to have_css(
      "#comment-node-#{ama_comment.id} .spec-op-author[data-tooltip='Ask Me Anything']",
      count: 2,
    )
  end

  it "renders CSS pseudo-element depth indicators on nested comments but not root comments", :aggregate_failures, :js do
    depth2_comment = create(:comment, user: commenter, parent: child_comment, commentable: article)
    depth3_comment = create(:comment, user: commenter, parent: depth2_comment, commentable: article)
    depth4_comment = create(:comment, user: commenter, parent: depth3_comment, commentable: article)

    visit "#{article.path}/comments"

    expect(page).to have_css("#comment-node-#{depth4_comment.id}", visible: :visible)

    pseudo_styles = page.evaluate_script(<<~JS)
      [#{comment.id}, #{child_comment.id}, #{depth2_comment.id}, #{depth3_comment.id}, #{depth4_comment.id}].map((id) => {
        const node = document.querySelector(`#comment-node-${id}`);
        const inner = node.querySelector(":scope > .comment__inner");
        const before = window.getComputedStyle(inner, "::before");
        const after = window.getComputedStyle(inner, "::after");
        return {
          beforeContent: before.content,
          beforeBorderLeftWidth: before.borderLeftWidth,
          beforeBorderBottomWidth: before.borderBottomWidth,
          beforeRadius: before.borderBottomLeftRadius,
          beforeCursor: before.cursor,
          afterContent: after.content,
          afterBoxShadow: after.boxShadow,
          depthDots: window.getComputedStyle(node).getPropertyValue("--depth-dots").trim()
        };
      })
    JS

    # Root comment (depth 0) has no ::before or ::after depth indicators
    expect(pseudo_styles[0]["beforeContent"]).to eq("none")
    expect(pseudo_styles[0]["afterContent"]).to eq("none")

    # Nested comments (depths 1..4) render ::before L-line and ::after dot(s)
    expect(pseudo_styles[1]["beforeContent"]).to eq('""')
    expect(pseudo_styles[1]["beforeBorderLeftWidth"]).to eq("1px")
    expect(pseudo_styles[1]["beforeBorderBottomWidth"]).to eq("1px")
    expect(pseudo_styles[1]["beforeRadius"]).to eq("6px")
    expect(pseudo_styles[1]["beforeCursor"]).to eq("pointer")
    expect(pseudo_styles[1]["afterContent"]).to eq('""')
    expect(pseudo_styles[1]["depthDots"]).to eq("1")
    expect(pseudo_styles[1]["afterBoxShadow"]).to eq("none")

    expect(pseudo_styles[2]["depthDots"]).to eq("2")
    expect(pseudo_styles[2]["afterBoxShadow"]).to include("-7px 0px 0px")

    expect(pseudo_styles[3]["depthDots"]).to eq("3")
    expect(pseudo_styles[3]["afterBoxShadow"]).to include("-14px 0px 0px")

    expect(pseudo_styles[4]["depthDots"]).to eq("4")
    expect(pseudo_styles[4]["afterBoxShadow"]).to include("-21px 0px 0px")

    # Clicking the depth indicator area to the left of .comment__inner collapses the comment
    page.execute_script(<<~JS)
      const inner = document.querySelector("#comment-node-#{child_comment.id} > .comment__inner");
      const rect = inner.getBoundingClientRect();
      inner.dispatchEvent(new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
        clientX: rect.left - 8,
        clientY: rect.top + 24
      }));
    JS

    expect(page).to have_css(
      "details.js-comment-wrapper:not([open]) .js-collapse-comment-content",
      text: "#{child_comment.user.name} + 3 replies",
    )
  end
end
