require 'inline_svg'
require 'inline_svg/transform_pipeline'

class ACustomTransform < InlineSvg::CustomTransformation
  def transform(doc)
    doc
  end
end

class ASecondCustomTransform < ACustomTransform; end

describe InlineSvg::TransformPipeline::Transformations do
  context "looking up transformations" do
    it "returns built-in transformations when parameters are supplied" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        nocomment: 'irrelevant',
        class: 'irrelevant',
        style: 'irrelevant',
        title: 'irrelevant',
        desc: 'irrelevant',
        size: 'irrelevant',
        height: 'irrelevant',
        width: 'irrelevant',
        view_box: 'irrelevant',
        id: 'irrelevant',
        data: 'irrelevant',
        preserve_aspect_ratio: 'irrelevant',
        aria: 'irrelevant',
        aria_hidden: "true"
      )

      expect(transformations.map(&:class)).to match_array([
        InlineSvg::TransformPipeline::Transformations::NoComment,
        InlineSvg::TransformPipeline::Transformations::ClassAttribute,
        InlineSvg::TransformPipeline::Transformations::StyleAttribute,
        InlineSvg::TransformPipeline::Transformations::Title,
        InlineSvg::TransformPipeline::Transformations::Description,
        InlineSvg::TransformPipeline::Transformations::Size,
        InlineSvg::TransformPipeline::Transformations::Height,
        InlineSvg::TransformPipeline::Transformations::Width,
        InlineSvg::TransformPipeline::Transformations::ViewBox,
        InlineSvg::TransformPipeline::Transformations::IdAttribute,
        InlineSvg::TransformPipeline::Transformations::DataAttributes,
        InlineSvg::TransformPipeline::Transformations::PreserveAspectRatio,
        InlineSvg::TransformPipeline::Transformations::AriaAttributes,
        InlineSvg::TransformPipeline::Transformations::AriaHiddenAttribute
      ])
    end

    it "returns transformations in priority order" do
      built_ins = {
        desc:   { transform: InlineSvg::TransformPipeline::Transformations::Description, priority: 1 },
        size:   { transform: InlineSvg::TransformPipeline::Transformations::Size },
        title:  { transform: InlineSvg::TransformPipeline::Transformations::Title, priority: 2 }
      }

      allow(InlineSvg::TransformPipeline::Transformations).to \
        receive(:built_in_transformations).and_return(built_ins)

      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        {
          desc: "irrelevant",
          size: "irrelevant",
          title: "irrelevant",
        }
      )

      # Use `eq` here because we care about order
      expect(transformations.map(&:class)).to eq([
        InlineSvg::TransformPipeline::Transformations::Description,
        InlineSvg::TransformPipeline::Transformations::Title,
        InlineSvg::TransformPipeline::Transformations::Size,
      ])
    end

    it "returns no transformations when asked for an unknown transform" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        not_a_real_transform: 'irrelevant'
      )

      expect(transformations.map(&:class)).to match_array([])
    end

    it "does not return a transformation when a value is not supplied" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        title: nil
      )

      expect(transformations.map(&:class)).to match_array([])
    end
  end

  context "custom transformations" do
    before(:each) do
      InlineSvg.configure do |config|
        config.add_custom_transformation({transform: ACustomTransform, attribute: :my_transform, priority: 2})
        config.add_custom_transformation({transform: ASecondCustomTransform, attribute: :my_other_transform, priority: 1})
      end
    end

    after(:each) do
      InlineSvg.reset_configuration!
    end

    it "returns configured custom transformations" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        my_transform: :irrelevant
      )

      expect(transformations.map(&:class)).to match_array([ACustomTransform])
    end

    it "returns configured custom transformations in priority order" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        my_transform: :irrelevant,
        my_other_transform: :irrelevant
      )

      # Use `eq` here because we care about order:
      expect(transformations.map(&:class)).to eq([ASecondCustomTransform, ACustomTransform])
    end

    it "always prioritizes built-in transforms before custom transforms" do
      transformations = InlineSvg::TransformPipeline::Transformations.lookup(
        my_transform: :irrelevant,
        my_other_transform: :irrelevant,
        desc: "irrelevant"
      )

      # Use `eq` here because we care about order:
      expect(transformations.map(&:class)).to eq(
        [
          InlineSvg::TransformPipeline::Transformations::Description,
          ASecondCustomTransform,
          ACustomTransform
        ]
      )
    end
  end

end
