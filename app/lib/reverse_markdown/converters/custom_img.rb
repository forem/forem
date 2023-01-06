module ReverseMarkdown
  module Converters
    class CustomImg < Base
      def convert(node, state = {})
        alt   = node['alt']
        src   = node['data-src'] ? node['data-src'] : (node['data-srcset'] ? node['data-srcset'] : node['src'])
        title = extract_title(node)

        " ![#{alt}](#{src}#{title})"
      end
    end

    register :img, CustomImg.new
  end
end