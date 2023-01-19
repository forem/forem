require "securerandom"

# rubocop:disable Style/StringLiterals

class UniqueSvgTransform < InlineSvg::CustomTransformation
  def transform(doc, uniq_str = SecureRandom.hex[0..6])
    # nodes with id attributes
    doc.xpath('//*[@id]').each do |node|
      node_id = node.get_attribute 'id'
      node.set_attribute 'id', [node_id, uniq_str].join('-')
    end

    # nodes with id references
    doc.xpath('//*[@href]').each do |node|
      node_href = node.get_attribute 'href'
      node.set_attribute 'href', [node_href, uniq_str].join('-')
    end

    # nodes with fill references
    doc.xpath('//*[@fill]').each do |node|
      node_url = node.get_attribute 'fill'
      if (md = /url\((.+)\)/.match node_url)
        id = md[1]
      end
      next unless id

      new_url = "url(#{id}-#{uniq_str})"
      node.set_attribute 'fill', new_url
    end

    doc
  end
end

# rubocop:enable Style/StringLiterals
