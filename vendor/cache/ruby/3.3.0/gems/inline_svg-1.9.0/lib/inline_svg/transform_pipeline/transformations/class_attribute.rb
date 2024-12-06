module InlineSvg::TransformPipeline::Transformations
  class ClassAttribute < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        classes = (svg["class"] || "").split(" ")
        classes << value
        svg["class"] = classes.join(" ")
      end
    end
  end
end
