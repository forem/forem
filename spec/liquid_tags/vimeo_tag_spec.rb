require "rails_helper"
require "nokogiri"

RSpec.describe VimeoTag, type: :liquid_tag do
  let(:id) { "205930710" }

  def assert_parses(vimeo_id, token)
    liquid = Liquid::Template.parse("{% vimeo #{token} %}")
    html   = Nokogiri.parse(liquid.render).root
    expect(html.name).to eq "iframe"
    expect(html[:src]).to eq "https://player.vimeo.com/video/#{vimeo_id}"
    expect(html[:width]).to eq "710"
    expect(html[:height]).to eq "399"
  end

  it "accepts vimeo video id" do
    assert_parses id, id
  end

  it "accepts vimeo video id with wonky whitespace" do
    assert_parses id, " #{id}  \t"
  end

  it "accepts a vimeo video url" do
    assert_parses id, "https://vimeo.com/#{id}"
    assert_parses id, "vimeo.com/#{id}"
  end

  it "accepts a vimeo player url" do
    assert_parses id, "https://player.vimeo.com/video/#{id}"
    assert_parses id, "ps://player.vimeo.com/video/#{id}"
  end

  # NOTE: This is kinda dumb. It seems like the right answer is that
  # either it should run liquid before markdown, or markdown shouldn't
  # mess with the liquid tags (there is a fn to escape them, but it doesn't
  # seem to escape the url here)
  # https://github.com/thepracticaldev/dev.to/blob/master/app/labor/markdown_parser.rb#L73-L92
  # My test suite isn't entirely passing, and I've spent longer on this than I
  # wanted to, io Instead of looking into those, I'm going to just make this work  ¯\_(ツ)_/¯
  it "accepts urls that were over-eagerly turned into links by markdown" do
    assert_parses id, "<a href=\"https://vimeo.com/#{id}\">https://vimeo.com/192819855</a> "
  end
end
