require "rails_helper"

require "unique_svg_transform"

RSpec.describe UniqueSvgTransform do
  let(:input) { "#{fixture_path}/files/unicorn.svg" }
  let(:expectation) { File.read("#{fixture_path}/files/unicorn-unique.svg") }
  let(:pseudo_unique) { "87a63a" }

  it "transforms input doc into uniquely identified SVG" do
    doc = Nokogiri::XML(File.open(input))
    output = described_class.new(true).transform(doc, pseudo_unique).to_xml
    expect(output).to eq expectation
  end
end
