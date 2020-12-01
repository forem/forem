module RSpec
  module Core
    RSpec.describe MetadataFilter do
      describe ".filter_applies?" do
        attr_accessor :parent_group_metadata, :group_metadata, :example_metadata

        def create_metadatas
          container = self

          RSpec.describe "parent group", :caller => ["/foo_spec.rb:#{__LINE__}"] do; container.parent_group_metadata = metadata
            describe "group", :caller => ["/foo_spec.rb:#{__LINE__}"] do; container.group_metadata = metadata
              container.example_metadata = it("example", :caller => ["/foo_spec.rb:#{__LINE__}"], :if => true).metadata
            end
          end
        end

        let(:world) { World.new }

        before do
          allow(RSpec).to receive(:world) { world }
          create_metadatas
        end

        def filter_applies?(key, value, metadata)
          MetadataFilter.filter_applies?(key, value, metadata)
        end

        context "with locations" do
          let(:condition_key){ :locations }
          let(:parent_group_condition) do
            {File.expand_path(parent_group_metadata[:file_path]) => [parent_group_metadata[:line_number]]}
          end
          let(:group_condition) do
            {File.expand_path(group_metadata[:file_path]) => [group_metadata[:line_number]]}
          end
          let(:example_condition) do
            {File.expand_path(example_metadata[:file_path]) => [example_metadata[:line_number]]}
          end
          let(:between_examples_condition) do
            {File.expand_path(group_metadata[:file_path]) => [group_metadata[:line_number] + 1]}
          end
          let(:next_example_condition) do
            {File.expand_path(example_metadata[:file_path]) => [example_metadata[:line_number] + 2]}
          end

          let(:preceeding_declaration_lines) {{
            parent_group_metadata[:line_number] => parent_group_metadata[:line_number],
            group_metadata[:line_number] => group_metadata[:line_number],
            example_metadata[:line_number] => example_metadata[:line_number],
            (example_metadata[:line_number] + 1) => example_metadata[:line_number],
            (example_metadata[:line_number] + 2) => example_metadata[:line_number] + 2,
          }}

          before do
            expect(world).to receive(:preceding_declaration_line).at_least(:once) do |_file_name, line_num|
              preceeding_declaration_lines[line_num]
            end
          end

          it "matches the group when the line_number is the example group line number" do
            # this call doesn't really make sense since filter_applies? is only called
            # for example metadata not group metadata
            expect(filter_applies?(condition_key, group_condition, group_metadata)).to be(true)
          end

          it "matches the example when the line_number is the grandparent example group line number" do
            expect(filter_applies?(condition_key, parent_group_condition, example_metadata)).to be(true)
          end

          it "matches the example when the line_number is the parent example group line number" do
            expect(filter_applies?(condition_key, group_condition, example_metadata)).to be(true)
          end

          it "matches the example when the line_number is the example line number" do
            expect(filter_applies?(condition_key, example_condition, example_metadata)).to be(true)
          end

          it "matches when the line number is between this example and the next" do
            expect(filter_applies?(condition_key, between_examples_condition, example_metadata)).to be(true)
          end

          it "does not match when the line number matches the next example" do
            expect(filter_applies?(condition_key, next_example_condition, example_metadata)).to be(false)
          end
        end

        it "matches a proc with no arguments that evaluates to true" do
          expect(filter_applies?(:if, lambda { true }, example_metadata)).to be(true)
        end

        it "matches a proc that evaluates to true" do
          expect(filter_applies?(:if, lambda { |v| v }, example_metadata)).to be(true)
        end

        it "does not match a proc that evaluates to false" do
          expect(filter_applies?(:if, lambda { |v| !v }, example_metadata)).to be(false)
        end

        it "matches a proc with an arity of 2" do
          example_metadata[:foo] = nil
          expect(filter_applies?(:foo, lambda { |v, m| m == example_metadata }, example_metadata)).to be(true)
        end

        it "raises an error when the proc has an incorrect arity" do
          expect {
            filter_applies?(:if, lambda { |a,b,c| true }, example_metadata)
          }.to raise_error(ArgumentError)
        end

        it "matches an arbitrary object that has implemented `===` for matching" do
          matcher = Object.new
          def matcher.===(str)
            str.include?("T")
          end

          expect(filter_applies?(:foo, matcher, {:foo => "a sing"})).to be false
          expect(filter_applies?(:foo, matcher, {:foo => "a sTring"})).to be true
        end

        context "with an :ids filter" do
          it 'matches examples with a matching id and rerun_file_path' do
            metadata = { :scoped_id => "1:2", :rerun_file_path => "some/file" }
            expect(filter_applies?(:ids, { "some/file" => ["1:2"] }, metadata)).to be true
          end

          it 'does not match examples without a matching id' do
            metadata = { :scoped_id => "1:2", :rerun_file_path => "some/file" }
            expect(filter_applies?(:ids, { "some/file" => ["1:3"] }, metadata)).to be false
          end

          it 'does not match examples without a matching rerun_file_path' do
            metadata = { :scoped_id => "1:2", :rerun_file_path => "some/file" }
            expect(filter_applies?(:ids, { "some/file_2" => ["1:2"] }, metadata)).to be false
          end

          it 'matches the scoped id from a parent example group' do
            metadata = { :scoped_id => "1:2", :rerun_file_path => "some/file", :example_group => { :scoped_id => "1" } }
            expect(filter_applies?(:ids, { "some/file" => ["1"] }, metadata)).to be true
            expect(filter_applies?(:ids, { "some/file" => ["2"] }, metadata)).to be false
          end

          it 'matches only on entire id segments so (1 is not treated as a parent group of 11)' do
            metadata = { :scoped_id => "1:2", :rerun_file_path => "some/file", :example_group => { :scoped_id => "1" } }
            expect(filter_applies?(:ids, { "some/file" => ["1"] }, metadata)).to be true

            metadata = { :scoped_id => "11", :rerun_file_path => "some/file" }
            expect(filter_applies?(:ids, { "some/file" => ["1"] }, metadata)).to be false
          end
        end

        context "with a nested hash" do
          it 'matches when the nested entry matches' do
            metadata = { :foo => { :bar => "words" } }
            expect(filter_applies?(:foo, { :bar => /wor/ }, metadata)).to be(true)
          end

          it 'does not match when the nested entry does not match' do
            metadata = { :foo => { :bar => "words" } }
            expect(filter_applies?(:foo, { :bar => /sword/ }, metadata)).to be(false)
          end

          it 'does not match when the metadata lacks the key' do
            expect(filter_applies?(:foo, { :bar => /sword/ }, {})).to be(false)
          end

          it 'does not match when the metadata does not have a hash entry for the key' do
            metadata = { :foo => "words" }
            expect(filter_applies?(:foo, { :bar => /word/ }, metadata)).to be(false)
          end

          it 'matches when a metadata key is specified without a value and exists in the metadata hash' do
            metadata = { :foo => "words" }
            expect(filter_applies?(:foo, true, metadata)).to be(true)
          end
        end

        context "with an Array" do
          let(:metadata_with_array) do
            meta = nil
            RSpec.describe("group") do
              meta = example('example_with_array', :tag => [:one, 2, 'three', /four/]).metadata
            end
            meta
          end

          it "matches a symbol" do
            expect(filter_applies?(:tag, 'one', metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, :one, metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 'two', metadata_with_array)).to be(false)
          end

          it "matches a string" do
            expect(filter_applies?(:tag, 'three', metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, :three, metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 'tree', metadata_with_array)).to be(false)
          end

          it "matches an integer" do
            expect(filter_applies?(:tag, '2', metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 2, metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 3, metadata_with_array)).to be(false)
          end

          it "matches a regexp" do
            expect(filter_applies?(:tag, 'four', metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 'fourtune', metadata_with_array)).to be(true)
            expect(filter_applies?(:tag, 'fortune', metadata_with_array)).to be(false)
          end

          it "matches a proc that evaluates to true" do
            expect(filter_applies?(:tag, lambda { |values| values.include? 'three' }, metadata_with_array)).to be(true)
          end

          it "does not match a proc that evaluates to false" do
            expect(filter_applies?(:tag, lambda { |values| values.include? 'nothing' }, metadata_with_array)).to be(false)
          end

          it 'matches when a metadata key is specified without a value and exists in the metadata hash' do
            expect(filter_applies?(:tag, true, metadata_with_array)).to be(true)
          end
        end
      end
    end
  end
end
