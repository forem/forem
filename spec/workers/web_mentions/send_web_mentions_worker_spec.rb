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
        article_url = article_url(article)
        article.update(canonical_url: canonical_url)

        allow(HTTParty).to receive(:post)
        webmention
        worker.perform(comment.id)
        expect(HTTParty).to have_received(:post).
          with(webmention_url, { "source": article_url, "target": canonical_url })
      end
    end
  end
end
