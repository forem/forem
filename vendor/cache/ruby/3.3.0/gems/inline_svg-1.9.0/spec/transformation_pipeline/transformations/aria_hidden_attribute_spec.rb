require 'inline_svg/transform_pipeline'

describe InlineSvg::TransformPipeline::Transformations::AriaHiddenAttribute do
  it "adds an aria-hidden='true' attribute to a SVG document" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::AriaHiddenAttribute.create_with_value(true)

    expect(transformation.transform(document).to_html).to eq(
      "<svg aria-hidden=\"true\">Some document</svg>\n"
    )
  end
end
