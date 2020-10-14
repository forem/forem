require "rails_helper"

# For webmentions to work, we basically need two things:
# A source of webmentions(i.e: article on FOREM)
# A target to which webmentions will be sent (i.e article's canonical URL)
# Since FOREM will be the source of webmentions, every article should contain Microformats
# that allows the receiving website to parse various information from the source article
# such as the comment's content, the author of the comment and their information(name, picture, etc..)
# Ref: http://microformats.org/wiki/h-entry

RSpec.describe "Webmention Microformats", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, with_canonical_url: true, show_comments: true) }

  before do
    sign_in user
  end

  context "when article" do
    it "has h-entry microformat" do
      visit article.path
      expect(page).to have_css(".h-entry")
    end

    it "has u-in-reply-to microformat" do
      visit article.path
      expect(page).to have_css(".u-in-reply-to")
    end

    it "has comment microformats" do
      create(:comment, commentable: article, user: user)
      visit "#{article.path}/comments"

      expect(page).to have_css(".u-author.h-card")
      expect(page).to have_css(".p-name")
      expect(page).to have_css(".u-url")
      expect(page).to have_css(".dt-published")
      expect(page).to have_css(".e-content")
    end
  end
end
