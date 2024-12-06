require 'inline_svg/transform_pipeline'

describe InlineSvg::TransformPipeline::Transformations::PreserveAspectRatio do
  it "adds preserveAspectRatio attribute to a SVG document" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation = InlineSvg::TransformPipeline::Transformations::PreserveAspectRatio.create_with_value("xMaxYMax meet")
    expect(transformation.transform(document).to_html).to eq(
      "<svg preserveAspectRatio=\"xMaxYMax meet\">Some document</svg>\n"
    )
  end
end
