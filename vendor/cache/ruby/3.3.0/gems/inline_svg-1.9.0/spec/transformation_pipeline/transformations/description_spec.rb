require 'inline_svg/transform_pipeline'

describe InlineSvg::TransformPipeline::Transformations::Description do
  it "adds a desc element to the SVG document" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::Description.create_with_value("Some Description")

    expect(transformation.transform(document).to_html).to eq(
      "<svg><desc>Some Description</desc>Some document</svg>\n"
    )
  end

  it "overwrites the content of an existing description element" do
    document = Nokogiri::XML::Document.parse('<svg><desc>My Description</desc>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::Description.create_with_value("Some Description")

    expect(transformation.transform(document).to_html).to eq(
      "<svg><desc>Some Description</desc>Some document</svg>\n"
    )
  end

  it "handles empty SVG documents" do
    document = Nokogiri::XML::Document.parse('<svg></svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::Description.create_with_value("Some Description")

    expect(transformation.transform(document).to_html).to eq(
      "<svg><desc>Some Description</desc></svg>\n"
    )
  end
end
