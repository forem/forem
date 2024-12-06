module MetaInspector
  module Parsers
    class MetaTagsParser < Base
      delegate :parsed => :@main_parser

      def meta_tags
        {
          'name'        => meta_tags_by('name'),
          'http-equiv'  => meta_tags_by('http-equiv'),
          'property'    => meta_tags_by('property'),
          'charset'     => [charset_from_meta_charset]
        }
      end

      def meta_tag
        convert_each_array_to_first_element_on meta_tags
      end

      def meta
        meta_tag['name']
          .merge(meta_tag['http-equiv'])
          .merge(meta_tag['property'])
          .merge('charset' => meta_tag['charset'])
      end

      # Returns the charset from the meta tags, searching in this order:
      # <meta charset='utf-8' />
      # <meta http-equiv="Content-Type" content="text/html; charset=windows-1252" />
      def charset
        @charset ||= (charset_from_meta_charset || charset_from_meta_content_type)
      end

      private

      def charset_from_meta_charset
        parsed.css('meta[charset]')[0].attributes['charset'].value rescue nil
      end

      def charset_from_meta_content_type
        parsed.css("meta[http-equiv='Content-Type']")[0]
          .attributes['content'].value.split(';')[1].split('=')[1] rescue nil
      end

      def meta_tags_by(attribute)
        hash = {}
        parsed.css("meta[@#{attribute}]").map do |tag|
          name    = tag.attributes[attribute].value.downcase rescue nil
          content = tag.attributes['content'].value rescue nil

          if name && content
            hash[name] ||= []
            hash[name] << content
          end
        end
        hash
      end

      def convert_each_array_to_first_element_on(hash)
        hash.each_pair do |k, v|
          hash[k] = if v.is_a?(Hash)
                      convert_each_array_to_first_element_on(v)
                    elsif v.is_a?(Array)
                      v.first
                    else
                      v
                    end
        end
      end

    end
  end
end
