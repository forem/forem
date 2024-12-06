require 'spec_helper'

describe MetaInspector::Parser do
  let(:doc)    { MetaInspector::Document.new('http://pagerankalert.com') }
  let(:parser) { MetaInspector::Parser.new(doc) }

  it "should have a Nokogiri::HTML::Document as parsed" do
    expect(parser.parsed.class).to eq(Nokogiri::HTML::Document)
  end

  it "should return the document as a string" do
    expect(parser.to_s.class).to eq(String)
  end
end
