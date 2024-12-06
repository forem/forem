require 'inline_svg/transform_pipeline'

describe InlineSvg::TransformPipeline::Transformations::ViewBox do
  it "adds viewBox attribute to a SVG document" do
    document = Nokogiri::XML::Document.parse('<svg>Some document</svg>')
    transformation =
      InlineSvg::TransformPipeline::Transformations::ViewBox
        .create_with_value("0 0 100 100")
    expect(transformation.transform(document).to_html).to eq(
      "<svg viewBox=\"0 0 100 100\">Some document</svg>\n"
    )
  end
end
