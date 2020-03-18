require "rails_helper"

RSpec.describe MarkdownFixer, type: :labor do
  let(:sample_text) { Faker::Book.title }

  def front_matter(title: "", description: "")
    <<~HEREDOC
      ---
      title: #{title}
      description: #{description}
      ---
    HEREDOC
  end

  describe "::add_quotes_to_title" do
    it "does not do anything outside the front matter" do
      result = described_class.add_quotes_to_title(sample_text)
      expect(result).to eq(sample_text)
    end

    it "escapes a simple title" do
      result = described_class.add_quotes_to_title(front_matter(title: sample_text))
      expect(result).to eq(front_matter(title: %("#{sample_text}")))
    end

    it "does not escape a title that came pre-wrapped in single quotes" do
      legacy_title = "'#{sample_text}'"
      result = described_class.add_quotes_to_title(front_matter(title: legacy_title))
      expect(result).to eq(front_matter(title: legacy_title))
    end

    it "does not escape a title that came pre-wrapped in double quotes" do
      legacy_title = "\"#{sample_text}\""
      result = described_class.add_quotes_to_title(front_matter(title: legacy_title))
      expect(result).to eq(front_matter(title: legacy_title))
    end

    it "handles a complex title" do
      legacy_title = %(Book review: "#{sample_text}", part 1 I'm #testing)
      expected_title = "\"Book review: \\\"#{sample_text}\\\", part 1 I'm #testing\""
      result = described_class.add_quotes_to_title(front_matter(title: legacy_title))
      expect(result).to eq(front_matter(title: expected_title))
    end

    it "handles a title with colons" do
      title = "Title: with colons"
      result = described_class.add_quotes_to_title(front_matter(title: title))
      expect(result).to eq(front_matter(title: %("#{title}")))
    end
  end

  describe "::add_quotes_to_description" do
    it "does not do anything outside the front matter" do
      result = described_class.add_quotes_to_description(sample_text)
      expect(result).to eq(sample_text)
    end

    it "escapes a simple description" do
      result = described_class.add_quotes_to_description(front_matter(description: sample_text))
      expect(result).to eq(front_matter(description: %("#{sample_text}")))
    end

    it "does not escape a description that came pre-wrapped in single quotes" do
      legacy_description = "'#{sample_text}'"
      result = described_class.
        add_quotes_to_description(front_matter(description: legacy_description))
      expect(result).to eq(front_matter(description: legacy_description))
    end

    it "does not escape a description that came pre-wrapped in double quotes" do
      legacy_description = "\"#{sample_text}\""
      result = described_class.
        add_quotes_to_description(front_matter(description: legacy_description))
      expect(result).to eq(front_matter(description: legacy_description))
    end

    it "handles a complex description" do
      legacy_description = %(Book review: "#{sample_text}", part 1 I'm #testing)
      expected_description = "\"Book review: \\\"#{sample_text}\\\", part 1 I'm #testing\""
      result = described_class.
        add_quotes_to_description(front_matter(description: legacy_description))
      expect(result).to eq(front_matter(description: expected_description))
    end

    it "handles a description with colons" do
      description = "Description: with colons"
      result = described_class.add_quotes_to_description(front_matter(description: description))
      expect(result).to eq(front_matter(description: %("#{description}")))
    end
  end

  describe "::convert_new_lines" do
    it "handles text with \r\n" do
      title = "\"hmm\"\r\n"
      expected_title = "\"hmm\"\n"
      result = described_class.convert_new_lines(front_matter(title: title))
      expect(result).to eq(front_matter(title: expected_title))
    end
  end

  describe "::fix_all" do
    it "escapes title and description" do
      result = described_class.
        fix_all(front_matter(title: sample_text, description: sample_text))
      expected_result = front_matter(title: %("#{sample_text}"), description: %("#{sample_text}"))
      expect(result).to eq(expected_result)
    end

    context "when description is empty" do
      it "escapes title and description" do
        result = described_class.
          fix_all("---\ntitle: #{sample_text}\ndescription:\ntags: \n---\n")
        expected_result = "---\ntitle: \"#{sample_text}\"\ndescription: \"\"\ntags: \n---\n"
        expect(result).to eq(expected_result)
      end
    end
  end

  describe "::fix_for_preview" do
    it "escapes title and description" do
      result = described_class.
        fix_for_preview(front_matter(title: sample_text, description: sample_text))
      expected_result = front_matter(title: %("#{sample_text}"), description: %("#{sample_text}"))
      expect(result).to eq(expected_result)
    end
  end

  describe "::underscores_in_usernames" do
    it "escapes underscores in a username" do
      test_string1 = "@_xy_"
      expected_result1 = "@\\_xy\\_"
      test_string2 = "@_x_y_"
      expected_result2 = "@\\_x\\_y\\_"

      expect(described_class.underscores_in_usernames(test_string1)).to eq(expected_result1)
      expect(described_class.underscores_in_usernames(test_string2)).to eq(expected_result2)
    end

    it "does not escape underscores when it is not a username" do
      test_string = "_make this cursive_"
      expected_result = "_make this cursive_"
      expect(described_class.underscores_in_usernames(test_string)).to eq(expected_result)
    end

    it "escapes correctly and ignores underscored username in code and code block" do
      input = <<~INPUT
        @_dev_

        ```ruby
        @_no_escape_codeblock
        ```

        `@_no_escape_code`
      INPUT

      result = described_class.underscores_in_usernames(input)

      expect(result).to include("@\\_dev\\_")
      expect(result).to include("@_no_escape_codeblock", "@_no_escape_code")
    end
  end
end
