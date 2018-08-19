require "rails_helper"
require "nokogiri"

RSpec.describe VimeoTag, type: :liquid_template do
  let(:id) { "205930710" }

  def assert_parses(vimeo_id, token)
    liquid = Liquid::Template.parse("{% vimeo #{token} %}")
    html   = Nokogiri.parse(liquid.render).root
    expect(html.name).to eq "iframe"
    expect(html[:src]).to eq "https://player.vimeo.com/video/#{vimeo_id}"
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
end
