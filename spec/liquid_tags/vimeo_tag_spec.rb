require "rails_helper"
require "nokogiri"

RSpec.describe VimeoTag, type: :liquid_tag do
  let(:id) { "205930710" }

  def assert_parses(vimeo_id, token, privacy_hash: nil)
    liquid = Liquid::Template.parse("{% vimeo #{token} %}")
    html   = Nokogiri.parse(liquid.render).root
    expected_src = "https://player.vimeo.com/video/#{vimeo_id}"
    expected_src += "?h=#{privacy_hash}" if privacy_hash
    expect(html.name).to eq "iframe"
    expect(html[:src]).to eq expected_src
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

  it "accepts urls that were turned into links by markdown" do
    assert_parses id, "<a href=\"https://vimeo.com/#{id}\">https://vimeo.com/#{id}</a> "
  end

  it "keeps the privacy hash of an unlisted video url" do
    assert_parses id, "https://vimeo.com/#{id}/fef4791276", privacy_hash: "fef4791276"
    assert_parses id, "vimeo.com/#{id}/fef4791276?share=copy", privacy_hash: "fef4791276"
  end

  it "keeps the h parameter of a player url" do
    assert_parses id, "https://player.vimeo.com/video/#{id}?h=a68f6ed1f5", privacy_hash: "a68f6ed1f5"
    assert_parses id, "https://player.vimeo.com/video/#{id}?autoplay=1&h=a68f6ed1f5", privacy_hash: "a68f6ed1f5"
  end

  it "does not treat other path segments or parameters as a privacy hash" do
    assert_parses id, "https://vimeo.com/#{id}/recommended"
    assert_parses id, "https://vimeo.com/#{id}?h=zzzzzzzz"
  end

  it "accepts the hash in an unlisted url that markdown turned into a link" do
    url = "https://vimeo.com/#{id}/fef4791276"
    assert_parses id, "<a href=\"#{url}\">#{url}</a> ", privacy_hash: "fef4791276"
  end

  it "rejects non-numeric Vimeo IDs" do
    expect do
      Liquid::Template.parse('{% vimeo 205930710" onload="alert(1) %}')
    end.to raise_error(StandardError)

    expect do
      Liquid::Template.parse("{% vimeo https://vimeo.com/notanumber %}")
    end.to raise_error(StandardError)
  end
end
