module InlineSvg::TransformPipeline::Transformations
  class Title < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        node = Nokogiri::XML::Node.new("title", doc)
        node.content = value

        svg.search("title").each { |node| node.remove }
        svg.prepend_child(node)
      end
    end
  end
end
