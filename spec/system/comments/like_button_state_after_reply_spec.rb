require "rails_helper"

RSpec.describe "Like button and tooltip after replying", :js do
  let(:author) { create(:user, created_at: 1.week.ago) }
  let(:article) { create(:article, user: author, show_comments: true, with_tags: false, with_main_image: false) }
  let!(:parent_comment) { create(:comment, commentable: article, user: author) }

  before do
    create(:comment, commentable: article, user: author)
    sign_in author
  end

  it "keeps earlier comment Like buttons stacked above later ones and clears replying state after reply",
     :aggregate_failures do
    visit article.path.to_s
    wait_for_javascript

    expect(page).to have_css(".comment__footer .reaction-button[style*='z-index:']", minimum: 2)
    reaction_buttons = all(".comment__footer .reaction-button")
    expect(reaction_buttons.size).to be >= 2

    first_z_index_match = reaction_buttons[0][:style].match(/z-index:\s*(\d+)/)
    second_z_index_match = reaction_buttons[1][:style].match(/z-index:\s*(\d+)/)

    expect(first_z_index_match).to be_present
    expect(second_z_index_match).to be_present

    first_z_index = first_z_index_match[1].to_i
    second_z_index = second_z_index_match[1].to_i

    expect(first_z_index).to be > second_z_index

    # Open reply form on the parent comment and submit a reply
    within "#comment-node-#{parent_comment.id}" do
      find(".toggle-reply-form").click
      find(".c-autocomplete textarea[id*='textarea-for']").set("Thanks!")
      click_on("Submit")
    end

    # Parent comment should no longer be in the `replying` state
    within "#comment-node-#{parent_comment.id}" do
      expect(page).to have_css(".comment__details")
      expect(page).to have_no_css(".comment__details.replying")

      # Like button present and visible in the footer
      expect(page).to have_css(".comment__footer .reaction-button", visible: :visible)
    end
  end
end
