require "rails_helper"

RSpec.describe MarkdownProcessor::Fixer::FixAll, type: :service do
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
      methods = %i[
        add_quotes_to_title add_quotes_to_description lowercase_published
        modify_hr_tags convert_new_lines split_tags underscores_in_usernames
      ]

      expect(described_class::METHODS).to eq methods
    end
  end

  describe "#call" do
    it "escapes title and description" do
      markdown = front_matter(title: sample_text, description: sample_text)
      result = described_class.call(markdown)
      expected_result = front_matter(title: %("#{sample_text}"), description: %("#{sample_text}"))
      expect(result).to eq(expected_result)
    end

    context "when description is empty" do
      it "escapes title and description" do
        markdown = "---\ntitle: #{sample_text}\ndescription:\ntags: \n---\n"
        result = described_class.call(markdown)
        expected_result = "---\ntitle: \"#{sample_text}\"\ndescription: \"\"\ntags: \n---\n"
        expect(result).to eq(expected_result)
      end
    end

    context "when markdown is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end
  end
end
