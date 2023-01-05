module ReverseMarkdown
  module Converters
    class CustomPicture < Base
      def convert(node, state = {})
        imgs = node.search('img')
        if imgs.nil?
          return
        end

        node = node.search('img')[0]
        alt   = node['alt']
        src   = node['data-src'] ? node['data-src'] : (node['data-srcset'] ? node['data-srcset'] : node['src'])
        title = extract_title(node)

        " ![#{alt}](#{src}#{title})"
      end
    end

    register :picture, CustomPicture.new
  end
end