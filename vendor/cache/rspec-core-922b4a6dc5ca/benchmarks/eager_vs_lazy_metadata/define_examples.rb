top_level_example_groups = 25
examples = 25
nested_groups = 25
nested_examples = 25

top_level_example_groups.times do |tlg|
  RSpec.describe "Top level group #{tlg}", :foo => 3 do

    examples.times do |e|
      it("example #{e}", :bar => 4) { }
    end

    nested_groups.times do |ng|
      context "nested #{ng}" do
        nested_examples.times do |ne|
          it("example #{ne}") { }
        end
      end
    end
  end
end

