module RSpec
  module Matchers
    RSpec.describe Composable do
      RSpec::Matchers.define :matcher_using_surface_descriptions_in do |expected|
        match { false }
        failure_message { surface_descriptions_in(expected).to_s }
      end

      it "does not blow up when surfacing descriptions from an unreadable IO object" do
        expect {
          expect(3).to matcher_using_surface_descriptions_in(STDOUT)
        }.to fail_with(STDOUT.inspect)
      end

      it "does not blow up when surfacing descriptions from an unreadable Range object" do
        infinity = (1.0/0.0)
        infinite_range = -infinity..infinity
        expect {
          expect(1).to matcher_using_surface_descriptions_in(infinite_range)
        }.to fail_with(infinite_range.inspect)
      end

      it "does not blow up when surfacing descriptions from an Enumerable object whose #each includes the object itself" do
        array = ['something']
        array << array
        expect {
          expect(1).to matcher_using_surface_descriptions_in(array)
        }.to fail_with(array.to_s)
      end

      it "does not enumerate normal ranges" do
        range = 1..3
        expect {
          expect(1).to matcher_using_surface_descriptions_in(range)
        }.to fail_with(range.inspect)
      end

      it "doesn't mangle struct descriptions" do
        model = Struct.new(:a).new(1)
        expect {
          expect(1).to matcher_using_surface_descriptions_in(model)
        }.to fail_with(model.inspect)
      end

      RSpec::Matchers.define :all_but_one do |matcher|
        match do |actual|
          match_count = actual.count { |v| values_match?(matcher, v) }
          actual.size == match_count + 1
        end
      end

      context "when using a matcher instance that memoizes state multiple times in a composed expression" do
        it "works properly in spite of the memoization" do
          expect(["foo", "bar", "a"]).to all_but_one(have_string_length(3))
        end

        context "when passing a compound expression" do
          it "works properly in spite of the memoization" do
            expect(["A", "AB", "ABC"]).to all_but_one(
                have_string_length(1).or have_string_length(2)
            )
          end
        end
      end

      describe "cloning data structures containing matchers" do
        include Composable

        it "clones only the contained matchers" do
          matcher_1   = eq(1)
          matcher_2   = eq(2)
          object      = Object.new
          uncloneable = nil

          data_structure = {
            "foo"  => matcher_1,
            "bar"  => [matcher_2, uncloneable],
            "bazz" => object
          }

          cloned = with_matchers_cloned(data_structure)
          expect(cloned).not_to equal(data_structure)

          expect(cloned["foo"]).to be_a_clone_of(matcher_1)
          expect(cloned["bar"].first).to be_a_clone_of(matcher_2)
          expect(cloned["bazz"]).to equal(object)
        end

        it "copies custom matchers properly so they can work even though they have singleton behavior" do
          expect("foo").to with_matchers_cloned(have_string_length 3)
        end

        it 'does not blow up when passed an array containing an IO object' do
          stdout = STDOUT
          expect(with_matchers_cloned([stdout]).first).to equal(stdout)
        end
      end

      describe "when an unexpected call stack jump occurs" do
        RSpec::Matchers.define :cause_call_stack_jump do
          supports_block_expectations

          match do |block|
            begin
              block.call
              false
            rescue Exception # rubocop:disable Lint/RescueException
              true
            end
          end
        end

        it "issue a warning suggesting `expects_call_stack_jump?` has been improperly declared" do
          expect {
            x = 0
            expect { x += 1; exit }.to change { x }.and cause_call_stack_jump
          }.to raise_error(/no match results, [\.\w\s]+ declare `expects_call_stack_jump\?`/)
        end
      end
    end
  end
end
