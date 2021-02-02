require "rails_helper"

RSpec.describe MarkdownProcessor::Fixer::FixForComment, type: :service do
  let(:sample_text) { Faker::Book.title }

  def front_matter(title: "", description: "")
    <<~HEREDOC
      ---
      title: #{title}
      published: false
      description: #{description}
      ---
    HEREDOC
  end

  describe "defining constants" do
    it "defines METHODS" do
      methods = %i[modify_hr_tags underscores_in_usernames]
      expect(described_class::METHODS).to eq methods
    end
  end

  describe "#call" do
    it "escapes underscores in a username" do
      test_string1 = "@_xy_"
      expected_result1 = "@\\_xy\\_"
      test_string2 = "@_x_y_"
      expected_result2 = "@\\_x\\_y\\_"

      expect(described_class.call(test_string1)).to eq(expected_result1)
      expect(described_class.call(test_string2)).to eq(expected_result2)
    end

    it "modifies hr tags" do
      markdown =
        <<~HEREDOC
          #{front_matter(title: sample_text)}
          ---
          These hr tags should be converted to more dashes
          ---
        HEREDOC

      result = described_class.call(markdown)
      expect(result).to include("-------").twice
      expect(result).to include("---").at_least(:twice)
    end

    context "when markdown is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end
  end
end
