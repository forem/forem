require "inline_svg/transform_pipeline"

describe InlineSvg::TransformPipeline::Transformations::AriaAttributes do
  it "adds a role attribute to the SVG document" do
    document = Nokogiri::XML::Document.parse("<svg>Some document</svg>")
    transformation = InlineSvg::TransformPipeline::Transformations::AriaAttributes.create_with_value({})

    expect(transformation.transform(document).to_html).to eq(
      "<svg role=\"img\">Some document</svg>\n"
    )
  end

  context "aria-labelledby attribute" do
    it "adds 'title' when a title element is present" do
      document = Nokogiri::XML::Document.parse("<svg><title>Some title</title>Some document</svg>")
      transformation = InlineSvg::TransformPipeline::Transformations::AriaAttributes.create_with_value(true)

      expect(InlineSvg::IdGenerator).to receive(:generate).with("title", "Some title").
        and_return("some-id")

      expect(transformation.transform(document).to_html).to eq(
        "<svg role=\"img\" aria-labelledby=\"some-id\"><title id=\"some-id\">Some title</title>Some document</svg>\n"
      )
    end

    it "adds 'desc' when a description element is present" do
      document = Nokogiri::XML::Document.parse("<svg><desc>Some description</desc>Some document</svg>")
      transformation = InlineSvg::TransformPipeline::Transformations::AriaAttributes.create_with_value(true)

      expect(InlineSvg::IdGenerator).to receive(:generate).with("desc", "Some description").
        and_return("some-id")

      expect(transformation.transform(document).to_html).to eq(
        "<svg role=\"img\" aria-labelledby=\"some-id\"><desc id=\"some-id\">Some description</desc>Some document</svg>\n"
      )
    end

    it "adds both 'desc' and 'title' when title and description elements are present" do
      document = Nokogiri::XML::Document.parse("<svg><title>Some title</title><desc>Some description</desc>Some document</svg>")
      transformation = InlineSvg::TransformPipeline::Transformations::AriaAttributes.create_with_value(true)

      expect(InlineSvg::IdGenerator).to receive(:generate).with("title", "Some title").
        and_return("some-id")
      expect(InlineSvg::IdGenerator).to receive(:generate).with("desc", "Some description").
        and_return("some-other-id")

      expect(transformation.transform(document).to_html).to eq(
        "<svg role=\"img\" aria-labelledby=\"some-id some-other-id\"><title id=\"some-id\">Some title</title>\n<desc id=\"some-other-id\">Some description</desc>Some document</svg>\n"
      )
    end

    it "uses existing IDs when they exist" do
      document = Nokogiri::XML::Document.parse("<svg><title id='my-title'>Some title</title><desc id='my-desc'>Some description</desc>Some document</svg>")
      transformation = InlineSvg::TransformPipeline::Transformations::AriaAttributes.create_with_value(true)

      expect(InlineSvg::IdGenerator).to receive(:generate).with("my-title", "Some title").
        and_return("some-id")
      expect(InlineSvg::IdGenerator).to receive(:generate).with("my-desc", "Some description").
        and_return("some-other-id")

      expect(transformation.transform(document).to_html).to eq(
        "<svg role=\"img\" aria-labelledby=\"some-id some-other-id\"><title id=\"some-id\">Some title</title>\n<desc id=\"some-other-id\">Some description</desc>Some document</svg>\n"
      )
    end
  end
end
