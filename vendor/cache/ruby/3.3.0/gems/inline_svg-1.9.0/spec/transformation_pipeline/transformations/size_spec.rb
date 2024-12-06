require 'inline_svg/transform_pipeline'

describe InlineSvg::TransformPipeline::Transformations::Size do
  it "adds width and height attributes to a SVG document" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::Size.create_with_value("5% * 5%")

    expect(transformation.transform(document).to_html).to eq(
      "<svg width=\"5%\" height=\"5%\">Some document</svg>\n"
    )
  end

  it "adds the same width and height value when only passed one attribute" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::Size.create_with_value("5%")

    expect(transformation.transform(document).to_html).to eq(
      "<svg width=\"5%\" height=\"5%\">Some document</svg>\n"
    )
  end
end
