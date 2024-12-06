module MetaInspector
  module Parsers
    class TextsParser < Base
      delegate [:parsed, :meta] => :@main_parser

      # Returns the parsed document title, from the content of the <title> tag
      # within the <head> section.
      def title
        @title ||= parsed.css('head title').inner_text rescue nil
      end

      def best_title
        @best_title ||= find_best_title
      end

      def h1
        @h1 ||= find_heading('h1')
      end

      def h2
        @h2 ||= find_heading('h2')
      end

      def h3
        @h3 ||= find_heading('h3')
      end
      
      def h4
        @h4 ||= find_heading('h4')
      end

      def h5
        @h5 ||= find_heading('h5')
      end

      def h6
        @h6 ||= find_heading('h6')
      end

      # Returns the meta author, if present
      def author
        @author ||= meta['author']
      end

      # An author getter that returns the first non-nil description
      # from the following candidates:
      # - the standard meta description
      # - a link with the relational attribute "author"
      # - address tag which may contain the author
      # - the twitter:creator meta tag for the username
      def best_author
        @best_author ||= find_best_author
      end

      # Returns the meta description, if present
      def description
        @description ||= meta['description']
      end

      # A description getter that returns the first non-nill description
      # from the following candidates:
      # - the standard meta description
      # - the og:description meta tag
      # - the twitter:description meta tag
      # - the first paragraph with more than 120 characters
      def best_description
        @best_description ||= find_best_description
      end

      private

      def find_heading(heading)
        parsed.css(heading).map { |tag| tag.inner_text.strip.gsub(/\s+/, ' ') }.reject(&:empty?)
      end

      # Look for candidates per list of priority
      def find_best_title
        candidates = [
            meta['title'],
            meta['og:title'],
            parsed.css('head title'),
            parsed.css('body title'),
            parsed.css('h1').first
        ]
        candidates.flatten!
        candidates.compact!
        candidates.map! { |c| (c.respond_to? :inner_text) ? c.inner_text : c }
        candidates.map! { |c| c.strip.gsub(/\s+/, ' ') }
        candidates.first
      end

      def find_best_author
        candidates = [
          meta['author'],
          parsed.css('a[rel="author"]').first,
          parsed.css('address').first,
          meta['twitter:creator']
        ]
        candidates.flatten!
        candidates.compact!
        candidates.map! { |c| (c.respond_to? :inner_text) ? c.inner_text : c }
        candidates.map! { |c| c.strip.gsub(/\s+/, ' ') }
        candidates.first
      end

      def find_best_description
        candidates = [
          meta['description'],
          meta['og:description'],
          meta['twitter:description'],
          secondary_description
        ]
        candidates.find { |x| !x.to_s.empty? }
      end

      # Look for the first <p> block with 120 characters or more
      def secondary_description
        first_long_paragraph = parsed.search('//p[string-length() >= 120]').first
        first_long_paragraph ? first_long_paragraph.text : ''
      end
    end
  end
end
