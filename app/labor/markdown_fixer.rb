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
      markdown.gsub(/title:\s?(.*?)\n/m) do
        # $1 is the captured group (.*?)
        captured = $1.gsub(/(?<![\\])["]/, "\\\"")
        "title: \"#{captured}\"\n"
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
