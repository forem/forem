require "rails_helper"

RSpec.describe MediumTag, type: :liquid_tag do
  subject { Liquid::Template.parse("{% medium #{link} %}") }

  before { Liquid::Template.register_tag("medium", described_class) }

  let(:stubbed_scraper) { instance_double("MediumArticleRetrievalService") }
  let(:medium_link) { "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c" }
  let(:response) do
    {
      title: "Title",
      author: "Edison",
      author_image: "https://cdn-images-1.medium.com/fit/c/120/120/1*qFzi921ix0_kkrFMKYgELw.jpeg",
      reading_time: "4 min read",
      published_time: "2018-11-03T09:44:32.733Z",
      publication_date: "Nov 3, 2018",
      url: "https://medium.com/@edisonywh"
    }
  end

  def generate_medium_tag(link)
    Liquid::Template.parse("{% medium #{link} %}")
  end

  context "when given valid medium url" do
    before do
      allow(MediumArticleRetrievalService).to receive(:new).with(medium_link).and_return(stubbed_scraper)
      allow(stubbed_scraper).to receive(:call).and_return(response)
    end

    it "renders the proper author name" do
      liquid = generate_medium_tag(medium_link)
      expect(liquid.render).to include(response[:author])
    end

    it "renders user image html" do
      liquid = generate_medium_tag(medium_link)
      expect(liquid.render).to include("<img")
    end

    it "renders article reading time" do
      liquid = generate_medium_tag(medium_link)
      expect(liquid.render).to include(response[:reading_time])
    end

    it "renders link to Medium profile" do
      liquid = generate_medium_tag(medium_link)
      expect(liquid.render).to include("<a href='#{response[:url]}'")
    end
  end

  it "raises an error when invalid" do
    expect { generate_medium_tag("invalid link") }.to raise_error("Invalid link URL or link URL does not exist")
  end
end
