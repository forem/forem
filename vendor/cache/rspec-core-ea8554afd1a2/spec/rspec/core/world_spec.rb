class Bar; end
class Foo; end

module RSpec::Core

  RSpec.describe RSpec::Core::World do
    let(:configuration) { RSpec.configuration }
    let(:world) { RSpec.world }

    describe '#reset' do
      it 'clears #example_groups' do
        world.example_groups << :example_group
        world.reset
        expect(world.example_groups).to be_empty
      end

      it 'clears #source_from_file cache', :isolated_directory do
        File.open('foo.rb', 'w') { |file| file.write('puts 1') }
        expect(world.source_from_file('foo.rb').lines).to eq(['puts 1'])

        File.open('foo.rb', 'w') { |file| file.write('puts 2') }
        expect(world.source_from_file('foo.rb').lines).to eq(['puts 1'])

        world.reset
        expect(world.source_from_file('foo.rb').lines).to eq(['puts 2'])
      end

      it 'clears #syntax_highlighter memoization' do
        expect { world.reset }.to change { world.syntax_highlighter.object_id }
      end

      it 'removes the previously assigned example group constants' do
        RSpec.describe "group"

        expect {
          RSpec.world.reset
        }.to change(RSpec::ExampleGroups, :constants).to([])
      end

      it 'clears #example_group_counts_by_spec_file' do
        RSpec.describe "group"

        expect {
          RSpec.world.reset
        }.to change { world.example_group_counts_by_spec_file }.to be_empty
      end
    end

    describe "#example_groups" do
      it "contains all registered example groups" do
        example_group = RSpec.describe("group") {}
        expect(world.example_groups).to include(example_group)
      end
    end

    describe "#all_example_groups" do
      it "contains all example groups from all levels of nesting" do
        RSpec.describe "eg1" do
          context "eg2" do
            context "eg3"
            context "eg4"
          end

          context "eg5"
        end

        RSpec.describe "eg6" do
          example
        end

        expect(RSpec.world.all_example_groups.map(&:description)).to match_array(%w[
          eg1 eg2 eg3 eg4 eg5 eg6
        ])
      end
    end

    describe "#all_examples" do
      it "contains all examples from all levels of nesting" do
        RSpec.describe do
          example("ex1")

          context "nested" do
            example("ex2")

            context "nested" do
              example("ex3")
              example("ex4")
            end
          end

          example("ex5")
        end

        RSpec.describe do
          example("ex6")
        end

        expect(RSpec.world.all_examples.map(&:description)).to match_array(%w[
          ex1 ex2 ex3 ex4 ex5 ex6
        ])
      end
    end

    describe "#preceding_declaration_line (again)" do
      let(:group) do
        RSpec.describe("group") do

          example("example") {}

        end
      end

      let(:second_group) do
        RSpec.describe("second_group") do

          example("second_example") {}

        end
      end

      let(:group_declaration_line) { group.metadata[:line_number] }
      let(:example_declaration_line) { group_declaration_line + 2 }

      def preceding_declaration_line(line_num)
        world.preceding_declaration_line(__FILE__, line_num)
      end

      context "with one example" do
        it "returns nil if no example or group precedes the line" do
          expect(preceding_declaration_line(group_declaration_line - 1)).to be_nil
        end

        it "returns the argument line number if a group starts on that line" do
          expect(preceding_declaration_line(group_declaration_line)).to eq(group_declaration_line)
        end

        it "returns the argument line number if an example starts on that line" do
          expect(preceding_declaration_line(example_declaration_line)).to eq(example_declaration_line)
        end

        it "returns line number of a group that immediately precedes the argument line" do
          expect(preceding_declaration_line(group_declaration_line + 1)).to eq(group_declaration_line)
        end

        it "returns line number of an example that immediately precedes the argument line" do
          expect(preceding_declaration_line(example_declaration_line + 1)).to eq(example_declaration_line)
        end
      end

      context "with two groups and the second example is registered first" do
        let(:second_group_declaration_line) { second_group.metadata[:line_number] }

        before do
          world.record(second_group)
          world.record(group)
        end

        it 'return line number of group if a group start on that line' do
          expect(preceding_declaration_line(second_group_declaration_line)).to eq(second_group_declaration_line)
        end
      end

      context "with groups from multiple files registered" do
        another_file = File.join(__FILE__, "another_spec_file.rb")

        let(:group_from_another_file) do
          instance_eval <<-EOS, another_file, 1
            RSpec.describe("third group") do

              example("inside of a gropu")

            end
          EOS
        end

        before do
          world.record(group)
          world.record(group_from_another_file)
        end

        it "returns nil if given a file name with no declarations" do
          expect(world.preceding_declaration_line("/some/other/file.rb", 100_000)).to eq(nil)
        end

        it "considers only declaration lines from the provided files", :aggregate_failures do
          expect(world.preceding_declaration_line(another_file, 1)).to eq(1)
          expect(world.preceding_declaration_line(another_file, 2)).to eq(1)
          expect(world.preceding_declaration_line(another_file, 3)).to eq(3)
          expect(world.preceding_declaration_line(another_file, 4)).to eq(3)
          expect(world.preceding_declaration_line(another_file, 5)).to eq(3)
          expect(world.preceding_declaration_line(another_file, 100_000)).to eq(3)

          expect(world.preceding_declaration_line(__FILE__, group_declaration_line + 1)).to eq(group_declaration_line)
        end
      end
    end

    describe '#source_from_file' do
      it 'caches Source instances by file path' do
        expect(world.source_from_file(__FILE__)).to be_a(RSpec::Support::Source).
                                                and have_attributes(:path => __FILE__).
                                                and equal(world.source_from_file(__FILE__))
      end
    end

    describe '#syntax_highlighter' do
      it 'returns a memoized SyntaxHighlighter' do
        expect(world.syntax_highlighter).to be_a(RSpec::Core::Formatters::SyntaxHighlighter).
                                        and equal(world.syntax_highlighter)
      end
    end

    describe "#announce_filters" do
      let(:reporter) { instance_spy(Reporter) }
      before { allow(world).to receive(:reporter) { reporter } }

      context "when --only-failures is passed" do
        before { configuration.force(:only_failures => true) }

        context "and all examples are filtered out" do
          before do
            configuration.filter_run_including :foo => 'bar'
          end

          it 'will ignore run_all_when_everything_filtered' do
            configuration.run_all_when_everything_filtered = true
            expect(world.filtered_examples).to_not receive(:clear)
            expect(world.inclusion_filter).to_not receive(:clear)
            world.announce_filters
          end
        end

        context "and `example_status_persistence_file_path` is not configured" do
          it 'aborts with a message explaining the config option must be set first' do
            configuration.example_status_persistence_file_path = nil
            world.announce_filters
            expect(reporter).to have_received(:abort_with).with(/example_status_persistence_file_path/, 1)
          end
        end

        context "and `example_status_persistence_file_path` is configured" do
          it 'does not abort' do
            configuration.example_status_persistence_file_path = "foo.txt"
            world.announce_filters
            expect(reporter).not_to have_received(:abort_with)
          end
        end
      end

      context "when --only-failures is not passed" do
        before { expect(configuration.only_failures?).not_to eq true }

        context "and `example_status_persistence_file_path` is not configured" do
          it 'does not abort' do
            configuration.example_status_persistence_file_path = nil
            world.announce_filters
            expect(reporter).not_to have_received(:abort_with)
          end
        end

        context "and `example_status_persistence_file_path` is configured" do
          it 'does not abort' do
            configuration.example_status_persistence_file_path = "foo.txt"
            world.announce_filters
            expect(reporter).not_to have_received(:abort_with)
          end
        end
      end

      context "with no examples" do
        before { allow(world).to receive(:example_count) { 0 } }

        context "with no filters" do
          it "announces" do
            expect(reporter).to receive(:message).
              with("No examples found.")
            world.announce_filters
          end
        end

        context "with an inclusion filter" do
          it "announces" do
            configuration.filter_run_including :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an inclusion filter and run_all_when_everything_filtered" do
          it "announces" do
            allow(configuration).to receive(:run_all_when_everything_filtered?) { true }
            configuration.filter_run_including :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an exclusion filter" do
          it "announces" do
            configuration.filter_run_excluding :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with a filter but with silence_filter_announcements" do
          it "does not announce" do
            configuration.silence_filter_announcements = true
            configuration.filter_run_including :foo => 'bar'
            expect(reporter).to_not receive(:message)
            world.announce_filters
          end
        end
      end

      context "with examples" do
        before { allow(world).to receive(:example_count) { 1 } }

        context "with no filters" do
          it "does not announce" do
            expect(reporter).not_to receive(:message)
            world.announce_filters
          end
        end
      end
    end
  end
end
