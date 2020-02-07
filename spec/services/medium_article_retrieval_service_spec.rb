require "rails_helper"

RSpec.describe MediumArticleRetrievalService, type: :service, vcr: {} do
  let(:expected_response) do
    {
      title: "My Ruby Journey: Hooking Things Up - Fave Product & Engineering - Medium",
      author: "Edison Yap",
      author_image: "https://miro.medium.com/fit/c/96/96/1*qFzi921ix0_kkrFMKYgELw.jpeg",
      reading_time: "4 min read",
      published_time: "2018-11-03T09:44:32.733Z",
      publication_date: anything,
      url: "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c"
    }
  end

  context "when the medium url is valid" do
    let(:medium_url) { "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c" }

    it "returns a valid response" do
      VCR.use_cassette("medium") do
        expect(described_class.call(medium_url)).to include(expected_response)
      end
    end
  end
end
