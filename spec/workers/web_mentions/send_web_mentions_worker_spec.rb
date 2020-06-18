require "rails_helper"

RSpec.describe WebMentions::SendWebMention, type: :worker do
  let(:worker) { subject }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:canonical_url) { "https://webmention.rocks/test/4" }
  let(:webmention_url) { "https://webmention.rocks/test/4/webmention" }
  let(:webmention) do
    stub_request(:get, canonical_url).
      to_return(status: 200, body:
      '<html lang="en">
        <head>
          <link href="https://webmention.rocks/test/4/webmention" rel="webmention">
        </head>
        <body>
        </body>
      </html>')
  end

  describe "send webmention" do
    context "when there's a new comment" do
      it "sends webmention" do
        article_url = ApplicationConfig["APP_DOMAIN"] + article.path
        article.update(canonical_url: canonical_url, support_webmentions: true)

        allow(RestClient).to receive(:post)
        webmention_url
        worker.perform(comment.id)
        expect(RestClient).to have_received(:post).
          with(webmention_url, { "source": article_url, "target": canonical_url })
      end
    end
  end
end
