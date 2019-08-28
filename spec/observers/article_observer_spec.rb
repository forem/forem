require "rails_helper"

RSpec.describe ArticleObserver, type: :observer do
  let(:user) { create(:user) }

  before do
    allow(SlackBot).to receive(:ping).and_return(true)
  end

  it "pings slack #activity if new article is created" do
    Article.observers.enable :article_observer do
      perform_enqueued_jobs do
        create(:article, user_id: user.id)
      end
    end
    expect(SlackBot).to have_received(:ping).once
  end
end
