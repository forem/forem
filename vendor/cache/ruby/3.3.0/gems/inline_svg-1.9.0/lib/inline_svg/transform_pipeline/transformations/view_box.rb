module InlineSvg::TransformPipeline::Transformations
  class ViewBox < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg["viewBox"] = value
      end
    end
  end
end
