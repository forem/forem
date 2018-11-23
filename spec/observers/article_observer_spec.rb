require "rails_helper"

RSpec.describe ArticleObserver, type: :observer do
  let(:user) { create(:user) }

  before do
    allow(SlackBot).to receive(:ping).and_return(true)
  end

  it "pings slack if user with warned role creates an article" do
    user.add_role :warned
    Article.observers.enable :article_observer do
      create(:article, user_id: user.id)
    end
    expect(SlackBot).to have_received(:ping).twice
  end
end
