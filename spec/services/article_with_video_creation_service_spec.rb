require "rails_helper"

RSpec.describe ArticleWithVideoCreationService, type: :service do
  let(:link) { "https://s3.amazonaws.com/dev-to-input-v0/video-upload__2d7dc29e39a40c7059572bca75bb646b" }

  before do
    stub_request(:get, /cloudfront.net/).to_return(status: 200, body: "", headers: {})
  end

  describe "#create!" do
    it "works" do
      Timecop.travel(3.weeks.ago)
      user = create(:user, editor_version: "v1")
      Timecop.return
      test = build_stubbed(:article, user: user, video: link).attributes.symbolize_keys
      article = described_class.new(test, user).create!
      expect(article.body_markdown.inspect).to include("description: \\ntags: \\n")
      expect(article.video_state).to eq("PROGRESSING")
    end
  end
end
