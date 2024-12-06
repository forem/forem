module InlineSvg::TransformPipeline::Transformations
  class Description < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        node = Nokogiri::XML::Node.new("desc", doc)
        node.content = value

        svg.search("desc").each { |node| node.remove }
        svg.prepend_child(node)
      end
    end
  end
end
