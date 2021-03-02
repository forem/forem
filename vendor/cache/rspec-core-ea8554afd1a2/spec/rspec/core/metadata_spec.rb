module RSpec
  module Core
    RSpec.describe Metadata do

      describe '.relative_path' do
        let(:here) { File.expand_path(".") }
        it "transforms absolute paths to relative paths" do
          expect(Metadata.relative_path(here)).to eq "."
        end
        it "transforms absolute paths to relative paths anywhere in its argument" do
          expect(Metadata.relative_path("foo #{here} bar")).to eq "foo . bar"
        end
        it "returns nil if passed an unparseable file:line combo" do
          expect(Metadata.relative_path("-e:1")).to be_nil
        end
        # I have no idea what line = line.sub(/\A([^:]+:\d+)$/, '\\1') is supposed to do
        it "gracefully returns nil if run in a secure thread" do
          # Ensure our call to `File.expand_path` is not cached as that is the insecure operation.
          Metadata.instance_eval { @relative_path_regex = nil }

          value = with_safe_set_to_level_that_triggers_security_errors do
            Metadata.relative_path(".")
          end

          # on some rubies, File.expand_path is not a security error, so accept "." as well
          expect([nil, "."]).to include(value)
        end

        it 'should not transform directories beginning with the same prefix' do
          #E.g. /foo/bar_baz is not relative to /foo/bar !!

          similar_directory = "#{File.expand_path(".")}_similar"
          expect(Metadata.relative_path(similar_directory)).to eq similar_directory
        end

      end

      specify 'RESERVED_KEYS contains all keys assigned by RSpec (and vice versa)' do
        group        = RSpec.describe("group")
        example      = group.example("example") { }
        nested_group = group.describe("nested")

        assigned_keys = group.metadata.keys | example.metadata.keys | nested_group.metadata.keys
        expect(RSpec::Core::Metadata::RESERVED_KEYS).to match_array(assigned_keys)
      end

      context "when created" do
        Metadata::RESERVED_KEYS.each do |key|
          it "prohibits :#{key} as a hash key for an example group" do
            expect {
              RSpec.describe("group", key => {})
            }.to raise_error(/:#{key} is not allowed/)
          end

          it "prohibits :#{key} as a hash key for an example" do
            group = RSpec.describe("group")
            expect {
              group.example("example", key => {})
            }.to raise_error(/:#{key} is not allowed/)
          end
        end

        it "uses :caller if passed as part of the user metadata" do
          m = nil

          RSpec.describe('group', :caller => ['example_file:42']) do
            m = metadata
          end

          expect(m[:location]).to eq("example_file:42")
        end
      end

      context "for an example" do
        let(:line_number) { __LINE__ + 3 }
        def metadata_for(*args)
          RSpec.describe("group description") do
            return example(*args).metadata
          end
        end
        alias example_metadata metadata_for

        RSpec::Matchers.define :have_value do |value|
          chain(:for) { |key| @key = key }

          match do |meta|
            expect(meta.fetch(@key)).to eq(value)
            expect(meta[@key]).to eq(value)
          end
        end

        it "stores the description args" do
          expect(metadata_for "example description").to have_value(["example description"]).for(:description_args)
        end

        it "ignores nil description args" do
          expect(example_metadata).to have_value([]).for(:description_args)
        end

        it "stores the full_description (group description + example description)" do
          expect(metadata_for "example description").to have_value("group description example description").for(:full_description)
        end

        it "creates an empty execution result" do
          expect(example_metadata[:execution_result].to_h.reject { |_, v| v.nil? } ).to eq({})
        end

        it "extracts file path from caller" do
          expect(example_metadata).to have_value(relative_path(__FILE__)).for(:file_path)
        end

        it "extracts line number from caller" do
          expect(example_metadata).to have_value(line_number).for(:line_number)
        end

        it "extracts location from caller" do
          expect(example_metadata).to have_value("#{relative_path(__FILE__)}:#{line_number}").for(:location)
        end

        it "uses :caller if passed as an option" do
          example_metadata = metadata_for('example description', :caller => ['example_file:42'])
          expect(example_metadata).to have_value("example_file:42").for(:location)
        end

        it "merges arbitrary options" do
          expect(metadata_for("desc", :arbitrary => :options)).to have_value(:options).for(:arbitrary)
        end

        it "points :example_group to the same hash object as other examples in the same group" do
          a = b = nil

          RSpec.describe "group" do
            a = example("foo").metadata[:example_group]
            b = example("bar").metadata[:example_group]
          end

          a[:description] = "new description"

          pending "Cannot maintain this and provide full `:example_group` backwards compatibility (see GH #1490):("
          expect(b[:description]).to eq("new description")
        end

        it 'does not include example-group specific keys' do
          example_meta = nil
          group_meta = nil

          RSpec.describe "group" do
            context "nested" do
              group_meta = metadata
              example_meta = example("foo").metadata
            end
          end

          expect(group_meta.keys - example_meta.keys).to contain_exactly(:parent_example_group)
        end
      end

      context "for an example group" do
        it 'does not include example specific keys' do
          example_meta = nil
          group_meta = nil

          RSpec.describe "group" do
            context "nested" do
              group_meta = metadata
              example_meta = example("foo").metadata
            end
          end

          expect(example_meta.keys - group_meta.keys).to contain_exactly(
            :execution_result, :last_run_status, :skip,
            :shared_group_inclusion_backtrace, :example_group
          )
        end
      end

      describe ":block" do
        context "for example group metadata" do
          it "contains the example group block" do
            block = Proc.new { }
            group = RSpec.describe("group", &block)
            expect(group.metadata[:block]).to equal(block)
          end
        end

        context "for example metadata" do
          it "contains the example block" do
            block = Proc.new { }
            group = RSpec.describe("group")
            example = group.example("example", &block)
            expect(example.metadata[:block]).to equal(block)
          end
        end
      end

      describe ":last_run_status" do
        it 'assigns it by looking up configuration.last_run_statuses[id]' do
          looked_up_ids = []
          last_run_statuses = Hash.new do |hash, id|
            looked_up_ids << id
            "some_status"
          end

          allow(RSpec.configuration).to receive(:last_run_statuses).and_return(last_run_statuses)
          example = RSpec.describe.example

          expect(example.metadata[:last_run_status]).to eq("some_status")
          expect(looked_up_ids).to eq [example.id]
        end
      end

      describe ":id" do
        define :have_id_with do |scoped_id|
          expected_id = "#{Metadata.relative_path(__FILE__)}[#{scoped_id}]"

          match do |group_or_example|
            group_or_example.metadata[:scoped_id] == scoped_id &&
            group_or_example.id == expected_id
          end

          failure_message do |group_or_example|
            "expected #{group_or_example.inspect}\n" \
            "   to have id: #{expected_id}\n" \
            "   but had id: #{group_or_example.id}\n" \
            "   and have scoped id: #{scoped_id}\n" \
            "   but had  scoped id: #{group_or_example.metadata[:scoped_id]}"
          end
        end

        context "on a top-level group" do
          it "is set to file[<group index>]" do
            expect(RSpec.describe).to have_id_with("1")
            expect(RSpec.describe).to have_id_with("2")
          end

          it "starts the count at 1 for each file" do
            instance_eval <<-EOS, "spec_1.rb", 1
              $group_1 = RSpec.describe
              $group_2 = RSpec.describe
            EOS

            instance_eval <<-EOS, "spec_2.rb", 1
              $group_3 = RSpec.describe
              $group_4 = RSpec.describe
            EOS

            expect($group_1.id).to end_with("spec_1.rb[1]")
            expect($group_2.id).to end_with("spec_1.rb[2]")
            expect($group_3.id).to end_with("spec_2.rb[1]")
            expect($group_4.id).to end_with("spec_2.rb[2]")
          end
        end

        context "on a nested group" do
          it "is set to file[<group index>:<group index>]" do
            top_level_group = RSpec.describe
            expect(top_level_group.describe).to have_id_with("1:1")
            expect(top_level_group.describe).to have_id_with("1:2")
          end
        end

        context "on an example" do
          it "is set to file[<group index>:<example index>]" do
            group = RSpec.describe
            expect(group.example).to have_id_with("1:1")
            expect(group.example).to have_id_with("1:2")
          end
        end

        context "when examples are interleaved with example groups" do
          it "counts both when assigning the index" do
            group = RSpec.describe
            expect(group.example ).to have_id_with("1:1")
            expect(group.describe).to have_id_with("1:2")
            expect(group.example ).to have_id_with("1:3")
            expect(group.example ).to have_id_with("1:4")
            expect(group.describe).to have_id_with("1:5")
          end
        end

        context "on an example defined in a shared group defined in a separate file" do
          it "uses the host group's file name as the prefix" do
            # Using eval in order to make ruby think this got defined in another file.
            instance_eval <<-EOS, "some/external/file.rb", 1
              RSpec.shared_examples "shared" do
                example { }
              end
            EOS

            group = RSpec.describe { include_examples "shared" }
            expect(group.examples.first.id).to start_with(Metadata.relative_path(__FILE__))
          end
        end
      end

      describe ":shared_group_inclusion_backtrace" do
        context "for an example group" do
          it "is not set since we do not yet need it internally (but we can add it in the future if needed)" do
            group = RSpec.describe("group")
            expect(group.metadata).not_to include(:shared_group_inclusion_backtrace)
          end
        end

        context "for an example" do
          context "not generated by a shared group" do
            it "is a blank array" do
              meta = nil
              RSpec.describe { meta = example { }.metadata }
              expect(meta).to include(:shared_group_inclusion_backtrace => [])
            end
          end

          context "generated by an unnested shared group included via metadata" do
            it "is an array containing an object with shared group name and inclusion location" do
              meta = nil

              RSpec.shared_examples_for("some shared behavior", :include_it => true) do
                meta = example { }.metadata
              end

              line = __LINE__ + 1
              RSpec.describe("Group", :include_it => true) { }

              expect(meta[:shared_group_inclusion_backtrace]).to match [ an_object_having_attributes(
                :shared_group_name  => "some shared behavior",
                :inclusion_location => a_string_including("#{Metadata.relative_path __FILE__}:#{line}")
              ) ]
            end
          end

          {
            :it_behaves_like  => "generates a nested group",
            :include_examples => "adds the examples directly to the host group"
          }.each do |inclusion_method, description|
            context "generated by an unnested shared group using an inclusion method that #{description}" do
              it "is an array containing an object with shared group name and inclusion location" do
                meta = nil

                RSpec.shared_examples_for("some shared behavior") do
                  meta = example { }.metadata
                end

                line = __LINE__ + 2
                RSpec.describe do
                  __send__ inclusion_method, "some shared behavior"
                end

                expect(meta[:shared_group_inclusion_backtrace]).to match [ an_object_having_attributes(
                  :shared_group_name  => "some shared behavior",
                  :inclusion_location => a_string_including("#{Metadata.relative_path __FILE__}:#{line}")
                ) ]
              end
            end

            context "generated by a nested shared group using an inclusion method that #{description}" do
              it "contains a stack frame for each inclusion, in the same order as ruby backtraces" do
                meta = nil

                RSpec.shared_examples_for "inner" do
                  meta = example { }.metadata
                end

                inner_line = __LINE__ + 2
                RSpec.shared_examples_for "outer" do
                  __send__ inclusion_method, "inner"
                end

                outer_line = __LINE__ + 2
                RSpec.describe do
                  __send__ inclusion_method, "outer"
                end

                expect(meta[:shared_group_inclusion_backtrace]).to match [
                  an_object_having_attributes(
                    :shared_group_name  => "inner",
                    :inclusion_location => a_string_including("#{Metadata.relative_path __FILE__}:#{inner_line}")
                  ),
                  an_object_having_attributes(
                    :shared_group_name  => "outer",
                    :inclusion_location => a_string_including("#{Metadata.relative_path __FILE__}:#{outer_line}")
                  ),
                ]
              end
            end
          end
        end
      end

      describe ":described_class" do
        value_from = lambda do |group|
          group.metadata[:described_class]
        end

        context "in an outer group" do
          define_method :value_for do |arg|
            value_from[RSpec.describe(arg)]
          end

          context "with a String" do
            it "returns nil" do
              expect(value_for "group").to be_nil
            end
          end

          context "with a Symbol" do
            it "returns the symbol" do
              expect(value_for :group).to be(:group)
            end
          end

          context "with a class" do
            it "returns the class" do
              expect(value_for String).to be(String)
            end

            context "when the class is Regexp" do
              it "returns the class" do
                expect(value_for Regexp).to be(Regexp)
              end
            end
          end
        end

        context "in a nested group" do
          it "inherits the parent group's described class" do
            value = nil

            RSpec.describe(Hash) do
              describe "sub context" do
                value = value_from[self]
              end
            end

            expect(value).to be(Hash)
          end

          it "sets the described class when passing a class" do
            value = nil

            RSpec.describe(String) do
              describe Array do
                value = value_from[self]
              end
            end

            expect(value).to be(Array)
          end

          it 'does not override the :described_class when passing no describe args' do
            value = nil

            RSpec.describe(String) do
              describe do
                value = value_from[self]
              end
            end

            expect(value).to be(String)
          end

          it "can override a parent group's described class using metadata" do
            parent_value = child_value = grandchild_value = nil

            RSpec.describe(String) do
              parent_value = value_from[self]

              describe "sub context" do
                metadata[:described_class] = Hash
                child_value = value_from[self]

                describe "sub context" do
                  grandchild_value = value_from[self]
                end
              end
            end

            expect(grandchild_value).to be(Hash)
            expect(child_value).to be(Hash)
            expect(parent_value).to be(String)
          end
        end
      end

      describe ":description" do
        context "on a example" do
          it "just has the example description" do
            value = nil

            RSpec.describe "group" do
              value = example("example").metadata[:description]
            end

            expect(value).to eq("example")
          end
        end

        context "on a group" do
          def group_value_for(*args)
            value = nil

            RSpec.describe(*args) do
              value = metadata[:description]
            end

            value
          end

          context "with a string" do
            it "provides the submitted description" do
              expect(group_value_for "group").to eq("group")
            end
          end

          context "with a non-string" do
            it "provides the string form of the submitted object" do
              expect(group_value_for Hash).to eq("Hash")
            end
          end

          context "with a non-string and a string" do
            it "concats the args" do
              expect(group_value_for Object, 'group').to eq("Object group")
            end
          end

          context "with a string and a non-string" do
            it "concats the args" do
              expect(group_value_for 'group', Object).to eq("group Object")
            end
          end

          context "with empty args" do
            it "returns empty string for [:description]" do
              expect(group_value_for()).to eq("")
            end
          end
        end
      end

      describe ":full_description" do
        context "on an example" do
          it "concats example group name and description" do
            value = nil

            RSpec.describe "group" do
              value = example("example").metadata[:full_description]
            end

            expect(value).to eq("group example")
          end
        end

        it "omits description from groups with a `nil` description" do
          value = nil

          RSpec.describe do
            value = example("example").metadata[:full_description]
          end

          expect(value).to eq("example")
        end

        it "omits description from groups with a description of `''`" do
          value = nil

          RSpec.describe "" do
            value = example("example").metadata[:full_description]
          end

          expect(value).to eq("example")
        end

        it "concats nested example group descriptions" do
          group_value = example_value = nil

          RSpec.describe "parent" do
            describe "child" do
              group_value = metadata[:full_description]
              example_value = example("example").metadata[:full_description]
            end
          end

          expect(group_value).to eq("parent child")
          expect(example_value).to eq("parent child example")
        end

        it "concats nested example group descriptions three deep" do
          grandparent_value = parent_value = child_value = example_value = nil

          RSpec.describe "grandparent" do
            grandparent_value = metadata[:full_description]
            describe "parent" do
              parent_value = metadata[:full_description]
              describe "child" do
                child_value = metadata[:full_description]
                example_value = example("example").metadata[:full_description]
              end
            end
          end

          expect(grandparent_value).to eq("grandparent")
          expect(parent_value).to eq("grandparent parent")
          expect(child_value).to eq("grandparent parent child")
          expect(example_value).to eq("grandparent parent child example")
        end

        %w[# . ::].each do |char|
          context "with a 2nd arg starting with #{char}" do
            it "removes the space" do
              value = nil

              RSpec.describe Array, "#{char}method" do
                value = metadata[:full_description]
              end

              expect(value).to eq("Array#{char}method")
            end
          end

          context "with a description starting with #{char} nested under a module" do
            it "removes the space" do
              value = nil

              RSpec.describe Object do
                describe "#{char}method" do
                  value = metadata[:full_description]
                end
              end

              expect(value).to eq("Object#{char}method")
            end
          end

          context "with a description starting with #{char} nested under a context string" do
            it "does not remove the space" do
              value = nil

              RSpec.describe(Array) do
                context "with 2 items" do
                  describe "#{char}method" do
                    value = metadata[:full_description]
                  end
                end
              end

              expect(value).to eq("Array with 2 items #{char}method")
            end
          end
        end
      end

      describe ":file_path" do
        it "finds the first non-rspec lib file in the caller array" do
          value = nil

          RSpec.describe(:caller => ["./lib/rspec/core/foo.rb", "#{__FILE__}:#{__LINE__}"]) do
            value = metadata[:file_path]
          end

          expect(value).to eq(relative_path(__FILE__))
        end
      end

      describe ":line_number" do
        def value_for(*args)
          value = nil

          @describe_line = __LINE__ + 1
          RSpec.describe("group", *args) do
            value = metadata[:line_number]
          end

          value
        end

        it "finds the line number with the first non-rspec lib file in the backtrace" do
          expect(value_for()).to eq(@describe_line)
        end

        it "finds the line number with the first spec file with drive letter" do
          expect(value_for(:caller => [ "C:/path/to/file_spec.rb:#{__LINE__}" ])).to eq(__LINE__)
        end

        it "uses the number after the first : for ruby 1.9" do
          expect(value_for(:caller => [ "#{__FILE__}:#{__LINE__}:999" ])).to eq(__LINE__)
        end
      end

      describe "child example group" do
        it "nests the parent's example group metadata" do
          child = parent = nil

          RSpec.describe Object, "parent" do
            parent = metadata
            describe { child = metadata }
          end

          expect(child[:parent_example_group]).to eq(parent)
        end
      end

      it 'does not have a `:parent_example_group` key for a top level group' do
        meta = RSpec.describe(Object).metadata
        expect(meta).not_to include(:parent_example_group)
      end

      describe "backwards compatibility" do
        before { allow_deprecation }

        describe ":example_group" do
          it 'issues a deprecation warning when the `:example_group` key is accessed' do
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 2, /:example_group/)
            RSpec.describe(Object, "group") do
              metadata[:example_group]
            end
          end

          it 'does not issue a deprecation warning when :example_group is accessed while applying configured filterings' do
            RSpec.configuration.include Module.new, :example_group => { :file_path => /.*/ }
            expect_no_deprecation
            RSpec.describe(Object, "group")
          end

          it 'can still access the example group attributes via [:example_group]' do
            meta = nil
            RSpec.describe(Object, "group") { meta = metadata }

            expect(meta[:example_group][:line_number]).to eq(__LINE__ - 2)
            expect(meta[:example_group][:description]).to eq("Object group")
          end

          it 'can access the parent example group attributes via [:example_group][:example_group]' do
            child = nil
            parent_line = __LINE__ + 1
            RSpec.describe(Object, "group", :foo => 3) do
              describe("nested") { child = metadata }
            end

            expect(child[:example_group][:example_group].to_h).to include(
              :foo => 3,
              :description => "Object group",
              :line_number => parent_line
            )
          end

          it "works properly with deep nesting" do
            inner_metadata = nil

            RSpec.describe "Level 1" do
              describe "Level 2" do
                describe "Level 3" do
                  inner_metadata = example("Level 4").metadata
                end
              end
            end

            expect(inner_metadata[:description]).to eq("Level 4")
            expect(inner_metadata[:example_group][:description]).to eq("Level 3")
            expect(inner_metadata[:example_group][:example_group][:description]).to eq("Level 2")
            expect(inner_metadata[:example_group][:example_group][:example_group][:description]).to eq("Level 1")
            expect(inner_metadata[:example_group][:example_group][:example_group][:example_group]).to be_nil
          end

          it "works properly with shallow nesting" do
            inner_metadata = nil

            RSpec.describe "Level 1" do
              inner_metadata = example("Level 2").metadata
            end

            expect(inner_metadata[:description]).to eq("Level 2")
            expect(inner_metadata[:example_group][:description]).to eq("Level 1")
            expect(inner_metadata[:example_group][:example_group]).to be_nil
          end

          it 'allows integration libraries like VCR to infer a fixture name from the example description by walking up nesting structure' do
            fixture_name_for = lambda do |meta|
              description = meta[:description]

              if example_group = meta[:example_group]
                [fixture_name_for[example_group], description].join('/')
              else
                description
              end
            end

            ex = inferred_fixture_name = nil

            RSpec.configure do |config|
              config.before(:example, :infer_fixture) { |e| inferred_fixture_name = fixture_name_for[e.metadata] }
            end

            RSpec.describe "Group", :infer_fixture do
              ex = example("ex") { }
            end.run

            raise ex.execution_result.exception if ex.execution_result.exception

            expect(inferred_fixture_name).to eq("Group/ex")
          end

          it 'can mutate attributes when accessing them via [:example_group]' do
            meta = nil

            RSpec.describe(String) do
              describe "sub context" do
                meta = metadata
              end
            end

            expect {
              meta[:example_group][:described_class] = Hash
            }.to change { meta[:described_class] }.from(String).to(Hash)
          end

          it 'can still be filtered via a nested key under [:example_group] as before' do
            meta = nil

            line = __LINE__ + 1
            RSpec.describe("group") { meta = metadata }

            applies = MetadataFilter.apply?(
              :any?,
              { :example_group => { :line_number => line } },
              meta
            )

            expect(applies).to be true
          end
        end

        describe ":example_group_block" do
          it 'returns the block' do
            meta = nil

            RSpec.describe "group" do
              meta = metadata
            end

            expect(meta[:example_group_block]).to be_a(Proc).and eq(meta[:block])
          end

          it 'issues a deprecation warning' do
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 2, /:example_group_block/)
            RSpec.describe "group" do
              metadata[:example_group_block]
            end
          end
        end

        describe ":describes" do
          context "on an example group metadata hash" do
            it 'returns the described_class' do
              meta = nil

              RSpec.describe Hash do
                meta = metadata
              end

              expect(meta[:describes]).to be(Hash).and eq(meta[:described_class])
            end

            it 'issues a deprecation warning' do
              expect_deprecation_with_call_site(__FILE__, __LINE__ + 2, /:describes/)
              RSpec.describe "group" do
                metadata[:describes]
              end
            end
          end

          context "an an example metadata hash" do
            it 'returns the described_class' do
              meta = nil

              RSpec.describe Hash do
                meta = example("ex").metadata
              end

              expect(meta[:describes]).to be(Hash).and eq(meta[:described_class])
            end

            it 'issues a deprecation warning' do
              expect_deprecation_with_call_site(__FILE__, __LINE__ + 2, /:describes/)
              RSpec.describe "group" do
                example("ex").metadata[:describes]
              end
            end
          end
        end
      end
    end
  end
end
