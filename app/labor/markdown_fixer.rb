class MarkdownFixer
  class << self
    def fix_all(markdown)
      methods = %i(add_quotes_to_title modify_hr_tags convert_new_lines split_tags)
      methods.reduce(markdown) { |result, method| send(method, result) }
    end

    def fix_for_preview(markdown)
      modify_hr_tags(add_quotes_to_title(markdown))
    end

    def add_quotes_to_title(markdown)
      markdown.gsub(/title:\s?(.*?)\n/m) do |target|
        # $1 is the captured group (.*?)
        captured_title = $1
        # The query below checks if the whole title is wrapped in
        # either single or double quotes.
        match = captured_title.scan(/(^".*"$|^'.*'$)/)
        if match.empty?
          # Double quotes that aren't already escaped will get esacped.
          # Then the whole title get warped in double quotes.
          parsed_title = captured_title.gsub(/(?<![\\])["]/, "\\\"")
          "title: \"#{parsed_title}\"\n"
        else
          # if the title comes pre-warped in either single or doublequotes,
          # no more processing is done
          target
        end
      end
    end

    # This turns --- into ------- after the first two,
    # because --- messes with front matter
    def modify_hr_tags(markdown)
      markdown.gsub(/^---/).with_index { |m, i| i > 1 ? "#{m}-----" : m }
    end

    def convert_new_lines(markdown)
      markdown.gsub("\r\n", "\n")
    end

    def split_tags(markdown)
      markdown.gsub(/\ntags:.*\n/) do |tags|
        tags.split(" #").join(",").gsub("#", "").gsub(":,", ": ")
      end
    end
  end
end
