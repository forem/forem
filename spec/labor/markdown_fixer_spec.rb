require "rails_helper"

RSpec.describe MarkdownFixer do
  let(:sample_title) { Faker::Book.title }

  def create_sample_markdown(title)
    <<~HEREDOC
      ---
      title: #{title}
      ---
    HEREDOC
  end

  describe "::add_quotes_to_title" do
    it "escapes simple title" do
      test = described_class.fix_all(create_sample_markdown(sample_title))
      expect(test).to eq create_sample_markdown(%("#{sample_title}"))
    end

    it "does not escape titles that came pre-wrapped in single quotes" do
      legacy_title = "'#{sample_title}'"
      test = described_class.fix_all(create_sample_markdown(legacy_title))
      expect(test).to eq create_sample_markdown(legacy_title)
    end

    it "does not escape titles that came pre-wrapped in double quotes" do
      legacy_title = "\"#{sample_title}\""
      test = described_class.fix_all(create_sample_markdown(legacy_title))
      expect(test).to eq create_sample_markdown(legacy_title)
    end

    it "handles complex title" do
      legacy_title = %(Book review: "#{sample_title}", part 1 I'm #testing)
      expected_title = "\"Book review: \\\"#{sample_title}\\\", part 1 I'm #testing\""
      test = described_class.fix_all(create_sample_markdown(legacy_title))
      expect(test).to eq create_sample_markdown(expected_title)
    end

    it "handles title with \r\n" do
      title = "\"hmm\"\r\n"
      expected_title = "\"hmm\"\n"
      test = described_class.fix_all(create_sample_markdown(title))
      expect(test).to eq create_sample_markdown(expected_title)
    end
  end
end
