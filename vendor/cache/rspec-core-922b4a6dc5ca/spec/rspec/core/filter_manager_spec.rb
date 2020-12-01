module RSpec::Core
  RSpec.describe FilterManager do
    def opposite(name)
      name =~ /^in/ ? name.sub(/^(in)/,'ex') : name.sub(/^(ex)/,'in')
    end

    subject(:filter_manager) { FilterManager.new }
    let(:inclusions) { filter_manager.inclusions }
    let(:exclusions) { filter_manager.exclusions }

    def prune(examples)
      # We want to enforce that our FilterManager, like a good citizen,
      # leaves the input array unmodified. There are a lot of code paths
      # through the filter manager, so rather than write one
      # `it 'does not mutate the input'` example that would not cover
      # all code paths, we're freezing the input here in order to
      # enforce that for ALL examples in this file that call `prune`,
      # the input array is not mutated.
      filter_manager.prune(examples.freeze)
    end

    %w[include inclusions exclude exclusions].each_slice(2) do |name, type|
      describe "##{name}" do
        subject(:rules) { send(type).rules }
        let(:opposite_rules) { send(opposite(type)).rules }

        it "merges #{type}" do
          filter_manager.send name, :foo => :bar
          filter_manager.send name, :baz => :bam
          expect(rules).to eq(:foo => :bar, :baz => :bam)
        end

        it "overrides previous #{type} with (via merge)" do
          filter_manager.send name, :foo => 1
          filter_manager.send name, :foo => 2
          expect(rules).to eq(:foo => 2)
        end

        it "deletes matching opposites" do
          filter_manager.exclusions.clear # defaults
          filter_manager.send opposite(name), :foo => 1
          filter_manager.send name, :foo => 2
          expect(rules).to eq(:foo => 2)
          expect(opposite_rules).to be_empty
        end

        if name == "include"
          context "with :full_description" do
            it "clears previous inclusions" do
              filter_manager.include :foo => :bar
              filter_manager.include :full_description => "value"
              expect(rules).to eq(:full_description => "value")
            end

            it "clears previous exclusion" do
              filter_manager.include :foo => :bar
              filter_manager.include :full_description => "value"
              expect(opposite_rules).to be_empty
            end

            it "does nothing when :full_description previously set" do
              filter_manager.include :full_description => "a_value"
              filter_manager.include :foo => :bar
              expect(rules).to eq(:full_description => "a_value")
            end
          end
        end
      end

      describe "##{name}_only" do
        subject(:rules) { send(type).rules }
        let(:opposite_rules) { send(opposite(type)).rules }

        it "replaces existing #{type}" do
          filter_manager.send name, :foo => 1, :bar => 2
          filter_manager.send "#{name}_only", :foo => 3
          expect(rules).to eq(:foo => 3)
        end

        it "deletes matching opposites" do
          filter_manager.send opposite(name), :foo => 1
          filter_manager.send "#{name}_only", :foo => 2
          expect(rules).to eq(:foo => 2)
          expect(opposite_rules).to be_empty
        end
      end

      describe "##{name}_with_low_priority" do
        subject(:rules) { send(type).rules }
        let(:opposite_rules) { send(opposite(type)).rules }

        it "ignores new #{type} if same key exists" do
          filter_manager.send name, :foo => 1
          filter_manager.send "#{name}_with_low_priority", :foo => 2
          expect(rules).to eq(:foo => 1)
        end

        it "ignores new #{type} if same key exists in opposite" do
          filter_manager.send opposite(name), :foo => 1
          filter_manager.send "#{name}_with_low_priority", :foo => 1
          expect(rules).to be_empty
          expect(opposite_rules).to eq(:foo => 1)
        end

        it "keeps new #{type} if same key exists in opposite but values are different" do
          filter_manager.send opposite(name), :foo => 1
          filter_manager.send "#{name}_with_low_priority", :foo => 2
          expect(rules).to eq(:foo => 2)
          expect(opposite_rules).to eq(:foo => 1)
        end
      end
    end

    describe "#prune" do
      def example_with(*args)
        RSpec.describe("group", *args).example("example")
      end

      shared_examples_for "example identification filter preference" do |type|
        it "prefers #{type} filter to exclusion filter" do
          group = RSpec.describe("group")
          included = group.example("include", :slow => true) {}; line = __LINE__
          excluded = group.example("exclude") {}

          add_filter(:line_number => line, :scoped_id => "1:1")
          filter_manager.exclude_with_low_priority :slow => true

          expect(prune([included, excluded])).to eq([included])
        end

        it "prefers #{type} on entire group to exclusion filter on a nested example" do
          # We way want to change this behaviour in future, see:
          # https://github.com/rspec/rspec-core/issues/779
          group = RSpec.describe("group"); line = __LINE__
          included = group.example("include", :slow => true)
          excluded = RSpec.describe.example

          add_filter(:line_number => line, :scoped_id => "1")
          filter_manager.exclude_with_low_priority :slow => true

          expect(prune([included, excluded])).to eq([included])
        end

        it "still applies inclusion filters to examples from files with no #{type} filters" do
          group = RSpec.describe("group")
          included_via_loc_or_id = group.example("inc via #{type}"); line = __LINE__
          excluded_via_loc_or_id = group.example("exc via #{type}", :foo)

          included_via_tag, excluded_via_tag = instance_eval <<-EOS, "some/other_spec.rb", 1
            group = RSpec.describe("group")
            [group.example("inc via tag", :foo), group.example("exc via tag")]
          EOS

          add_filter(:line_number => line, :scoped_id => "1:1")
          filter_manager.include_with_low_priority :foo => true

          expect(prune([
            included_via_loc_or_id, excluded_via_loc_or_id,
            included_via_tag, excluded_via_tag
          ]).map(&:description)).to eq([included_via_loc_or_id, included_via_tag].map(&:description))
        end

        it "skips examples in external files when included from a #{type} filtered file" do
          group = RSpec.describe("group")

          included_via_loc_or_id = group.example("inc via #{type}"); line = __LINE__

          # instantiate shared example in external file
          instance_eval <<-EOS, "a_shared_example.rb", 1
            RSpec.shared_examples_for("a shared example") do
              example("inside of a shared example")
            end
          EOS

          included_via_behaves_like = group.it_behaves_like("a shared example")
          test_inside_a_shared_example = included_via_behaves_like.examples.first

          add_filter(:line_number => line, :scoped_id => "1:1")

          expect(prune([
            included_via_loc_or_id, test_inside_a_shared_example
          ]).map(&:description)).to eq([included_via_loc_or_id].map(&:description))
        end
      end

      describe "location filtering" do
        include_examples "example identification filter preference", :location do
          def add_filter(options)
            filter_manager.add_location(__FILE__, [options.fetch(:line_number)])
          end
        end
      end

      describe "id filtering" do
        include_examples "example identification filter preference", :id do
          def add_filter(options)
            filter_manager.add_ids(__FILE__, [options.fetch(:scoped_id)])
          end
        end
      end

      context "with a location and an id filter" do
        it 'takes the set union of matched examples' do
          group = RSpec.describe("group")

          matches_id = group.example
          matches_line_number = group.example; line_1 = __LINE__
          matches_both = group.example; line_2 = __LINE__
          matches_neither = group.example

          filter_manager.add_ids(__FILE__, ["1:1", "1:3"])
          filter_manager.add_location(__FILE__, [line_1, line_2])

          expect(prune([
            matches_id, matches_line_number, matches_both, matches_neither
          ])).to eq([matches_id, matches_line_number, matches_both])
        end
      end

      context "with examples from multiple spec source files" do
        it "applies exclusions only to examples defined in files with no location filters" do
          group = RSpec.describe("group")
          line = __LINE__ + 1
          this_file_example = group.example("ex 1", :slow) { }

          # Using eval in order to make ruby think this got defined in another file.
          other_file_example = instance_eval "ex = nil; RSpec.describe('group') { ex = it('ex 2', :slow) { } }; ex", "some/external/file.rb", 1

          filter_manager.exclude_with_low_priority :slow => true

          expect {
            filter_manager.add_location(__FILE__, [line])
          }.to change {
            prune([this_file_example, other_file_example]).map(&:description)
          }.from([]).to([this_file_example.description])
        end
      end

      it "prefers description to exclusion filter" do
        group = RSpec.describe("group")
        included = group.example("include", :slow => true) {}
        excluded = group.example("exclude") {}
        filter_manager.include(:full_description => /include/)
        filter_manager.exclude_with_low_priority :slow => true
        expect(prune([included, excluded])).to eq([included])
      end

      it "includes objects with tags matching inclusions" do
        included = example_with({:foo => :bar})
        excluded = example_with
        filter_manager.include :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      it "excludes objects with tags matching exclusions" do
        included = example_with
        excluded = example_with({:foo => :bar})
        filter_manager.exclude :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      it "prefers exclusion when matches previously set inclusion" do
        included = example_with
        excluded = example_with({:foo => :bar})
        filter_manager.include :foo => :bar
        filter_manager.exclude :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      it "prefers inclusion when matches previously set exclusion" do
        included = example_with({:foo => :bar})
        excluded = example_with
        filter_manager.exclude :foo => :bar
        filter_manager.include :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      it "prefers previously set inclusion when exclusion matches but has lower priority" do
        included = example_with({:foo => :bar})
        excluded = example_with
        filter_manager.include :foo => :bar
        filter_manager.exclude_with_low_priority :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      it "prefers previously set exclusion when inclusion matches but has lower priority" do
        included = example_with
        excluded = example_with({:foo => :bar})
        filter_manager.exclude :foo => :bar
        filter_manager.include_with_low_priority :foo => :bar
        expect(prune([included, excluded])).to eq([included])
      end

      context "with multiple inclusion filters" do
        it 'includes objects that match any of them' do
          examples = [
            included_1 = example_with(:foo => true),
            included_2 = example_with(:bar => true),
                         example_with(:bazz => true)
          ]

          filter_manager.include :foo => true, :bar => true
          expect(prune(examples)).to contain_exactly(included_1, included_2)
        end
      end

      context "with :id filters" do
        it 'selects only the matched example when a single example id is given' do
          ex_1 = ex_2 = nil
          RSpec.describe do
            ex_1 = example
            ex_2 = example
          end

          filter_manager.add_ids(Metadata.relative_path(__FILE__), %w[ 1:2 ])
          expect(prune([ex_1, ex_2])).to eq([ex_2])
        end

        it 'can work with absolute file paths' do
          ex_1 = ex_2 = nil
          RSpec.describe do
            ex_1 = example
            ex_2 = example
          end

          filter_manager.add_ids(File.expand_path(__FILE__), %w[ 1:2 ])
          expect(prune([ex_1, ex_2])).to eq([ex_2])
        end

        it "can work with relative paths that lack the leading `.`" do
          path = Metadata.relative_path(__FILE__).sub(/^\.\//, '')

          ex_1 = ex_2 = nil
          RSpec.describe do
            ex_1 = example
            ex_2 = example
          end

          filter_manager.add_ids(path, %w[ 1:2 ])
          expect(prune([ex_1, ex_2])).to eq([ex_2])
        end

        it 'can select groups' do
          ex_1 = ex_2 = ex_3 = nil
          RSpec.describe { ex_1 = example }
          RSpec.describe do
            ex_2 = example
            ex_3 = example
          end

          filter_manager.add_ids(Metadata.relative_path(__FILE__), %w[ 2 ])
          expect(prune([ex_1, ex_2, ex_3])).to eq([ex_2, ex_3])
        end

        it 'uses the rerun file path when applying the id filter' do
          ex_1, ex_2 = instance_eval <<-EOS, "./some/spec.rb", 1
            ex_1 = ex_2 = nil

            RSpec.shared_examples "shared" do
              ex_1 = example("ex 1")
              ex_2 = example("ex 2")
            end

            [ex_1, ex_2]
          EOS

          RSpec.describe { include_examples "shared" }

          filter_manager.add_ids(__FILE__, %w[ 1:1 ])
          expect(prune([ex_1, ex_2]).map(&:description)).to eq([ex_1].map(&:description))
        end
      end
    end

    describe "#inclusions#description" do
      subject(:description) { inclusions.description }

      it 'cleans up the description' do
        project_dir = File.expand_path('.')
        expect(lambda { }.inspect).to include(project_dir)
        expect(lambda { }.inspect).to include(' (lambda)') if RUBY_VERSION > '1.9'
        expect(lambda { }.inspect).to include('0x')

        filter_manager.include :foo => lambda { }

        expect(description).not_to include(project_dir)
        expect(description).not_to include(' (lambda)')
        expect(description).not_to include('0x')
      end
    end

    describe "#exclusions#description" do
      subject(:description) { exclusions.description }

      it 'cleans up the description' do
        project_dir = File.expand_path('.')
        expect(lambda { }.inspect).to include(project_dir)
        expect(lambda { }.inspect).to include(' (lambda)') if RUBY_VERSION > '1.9'
        expect(lambda { }.inspect).to include('0x')

        filter_manager.exclude :foo => lambda { }

        expect(description).not_to include(project_dir)
        expect(description).not_to include(' (lambda)')
        expect(description).not_to include('0x')
      end

      it 'returns `{}` when it only contains the default filters' do
        expect(description).to eq({}.inspect)
      end

      it 'includes other filters' do
        filter_manager.exclude :foo => :bar
        expect(description).to eq({ :foo => :bar }.inspect)
      end

      it 'includes an overriden :if filter' do
        allow(RSpec).to receive(:deprecate)
        filter_manager.exclude :if => :custom_filter
        expect(description).to eq({ :if => :custom_filter }.inspect)
      end

      it 'includes an overriden :unless filter' do
        allow(RSpec).to receive(:deprecate)
        filter_manager.exclude :unless => :custom_filter
        expect(description).to eq({ :unless => :custom_filter }.inspect)
      end
    end

    describe ":if and :unless ExclusionFilters" do
      def example_with_metadata(metadata)
        value = nil
        RSpec.describe("group") do
          value = example('arbitrary example', metadata)
        end
        value
      end

      def exclude?(example)
        prune([example]).empty?
      end

      describe "the default :if filter" do
        it "does not exclude a spec with  { :if => true } metadata" do
          example = example_with_metadata(:if => true)
          expect(exclude?(example)).to be(false)
        end

        it "excludes a spec with  { :if => false } metadata" do
          example = example_with_metadata(:if => false)
          expect(exclude?(example)).to be(true)
        end

        it "excludes a spec with  { :if => nil } metadata" do
          example = example_with_metadata(:if => nil)
          expect(exclude?(example)).to be(true)
        end

        it "continues to be an exclusion even if exclusions are cleared" do
          example = example_with_metadata(:if => false)
          filter_manager.exclusions.clear
          expect(exclude?(example)).to be(true)
        end
      end

      describe "the default :unless filter" do
        it "excludes a spec with  { :unless => true } metadata" do
          example = example_with_metadata(:unless => true)
          expect(exclude?(example)).to be(true)
        end

        it "does not exclude a spec with { :unless => false } metadata" do
          example = example_with_metadata(:unless => false)
          expect(exclude?(example)).to be(false)
        end

        it "does not exclude a spec with { :unless => nil } metadata" do
          example = example_with_metadata(:unless => nil)
          expect(exclude?(example)).to be(false)
        end

        it "continues to be an exclusion even if exclusions are cleared" do
          example = example_with_metadata(:unless => true)
          filter_manager.exclusions.clear
          expect(exclude?(example)).to be(true)
        end
      end
    end
  end
end
