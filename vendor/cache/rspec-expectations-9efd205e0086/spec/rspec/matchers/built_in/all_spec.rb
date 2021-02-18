module RSpec::Matchers::BuiltIn
  RSpec.describe All do

    it_behaves_like 'an RSpec value matcher', :valid_value => ['A', 'A', 'A'], :invalid_value => ['A', 'A', 'B'], :disallows_negation => true do
      let(:matcher) { all( eq('A') ) }
    end

    describe 'description' do
      it 'provides a description' do
        matcher = all( eq('A') )
        expect(matcher.description).to eq 'all eq "A"'
      end
    end

    context 'when single matcher is given' do

      describe 'expect(...).to all(expected)' do

        it 'can pass' do
          expect(['A', 'A', 'A']).to all( eq('A') )
        end

        describe 'failure message' do

          context 'when the matcher has single-line failure message' do
            it 'returns the index of the failed object' do
              expect {
                expect(['A', 'A', 'A', 5, 'A']).to all( be_a(String) )
              }.to fail_with(dedent <<-EOS)
              |expected ["A", "A", "A", 5, "A"] to all be a kind of String
              |
              |   object at index 3 failed to match:
              |      expected 5 to be a kind of String
              EOS
            end

            it 'returns the indexes of all failed objects, not just the first one' do
              expect {
                expect(['A', 'A', 'A', 5, 6]).to all( be_a(String) )
              }.to fail_with(dedent <<-EOS)
              |expected ["A", "A", "A", 5, 6] to all be a kind of String
              |
              |   object at index 3 failed to match:
              |      expected 5 to be a kind of String
              |
              |   object at index 4 failed to match:
              |      expected 6 to be a kind of String
              EOS
            end
          end

          context 'when the matcher has multi-line failure message' do
            it 'returns the index of the failed object' do
              expect {
                expect(['A', 'A', 'A', 'C', 'A']).to all( eq('A') )
              }.to fail_with(dedent <<-EOS)
              |expected ["A", "A", "A", "C", "A"] to all eq "A"
              |
              |   object at index 3 failed to match:
              |      expected: "A"
              |           got: "C"
              |
              |      (compared using ==)
              EOS
            end

            it 'returns the indexes of all failed objects, not just the first one' do
              expect {
                expect(['A', 'B', 'A', 'C', 'A']).to all( eq('A') )
              }.to fail_with(dedent <<-EOS)
              |expected ["A", "B", "A", "C", "A"] to all eq "A"
              |
              |   object at index 1 failed to match:
              |      expected: "A"
              |           got: "B"
              |
              |      (compared using ==)
              |
              |   object at index 3 failed to match:
              |      expected: "A"
              |           got: "C"
              |
              |      (compared using ==)
              EOS
            end
          end

        end
      end
    end

    context 'when composed matcher is given' do

      describe 'expect(...).to all(expected)' do
        it 'can pass' do
          expect([3, 4, 7, 8]).to all( be_between(2, 5).or be_between(6, 9) )
        end
      end

      describe 'failure message' do

        context 'when a single object fails' do
          it 'returns the index of the failed object for the composed matcher' do
            expect {
              expect([3, 4, 7, 28]).to all( be_between(2, 5).or be_between(6, 9) )
            }.to fail_with(dedent <<-EOS)
              |expected [3, 4, 7, 28] to all be between 2 and 5 (inclusive) or be between 6 and 9 (inclusive)
              |
              |   object at index 3 failed to match:
              |         expected 28 to be between 2 and 5 (inclusive)
              |
              |      ...or:
              |
              |         expected 28 to be between 6 and 9 (inclusive)
            EOS
          end
        end

        context 'when a multiple objects fails' do
          it 'returns the indexes of the failed objects for the composed matcher, not just the first one' do
            expect {
              expect([3, 4, 27, 22]).to all( be_between(2, 5).or be_between(6, 9) )
            }.to fail_with(dedent <<-EOS)
              |expected [3, 4, 27, 22] to all be between 2 and 5 (inclusive) or be between 6 and 9 (inclusive)
              |
              |   object at index 2 failed to match:
              |         expected 27 to be between 2 and 5 (inclusive)
              |
              |      ...or:
              |
              |         expected 27 to be between 6 and 9 (inclusive)
              |
              |   object at index 3 failed to match:
              |         expected 22 to be between 2 and 5 (inclusive)
              |
              |      ...or:
              |
              |         expected 22 to be between 6 and 9 (inclusive)
            EOS
          end
        end
      end
    end

    context 'when composed in another matcher' do
      it 'returns the indexes of the failed objects only' do
        expect {
          expect([[false], [true]]).to all( all( be(true) ) )
        }.to fail_with(dedent <<-EOS)
          |expected [[false], [true]] to all all equal true
          |
          |   object at index 0 failed to match:
          |      expected [false] to all equal true
          |
          |         object at index 0 failed to match:
          |            expected true
          |                 got false
          EOS
      end
    end

    shared_examples "making a copy" do |copy_method|
      context "when making a copy via `#{copy_method}`" do

        let(:base_matcher) { eq(3) }
        let(:all_matcher) { all( base_matcher ) }
        let(:copied_matcher) { all_matcher.__send__(copy_method) }

        it "uses a copy of the base matcher" do
          expect(copied_matcher).not_to equal(all_matcher)
          expect(copied_matcher.matcher).not_to equal(base_matcher)
          expect(copied_matcher.matcher).to be_a(base_matcher.class)
          expect(copied_matcher.matcher.expected).to eq(3)
        end

        context 'when using a custom matcher' do

          let(:base_matcher) { custom_include(3) }

          it 'copies custom matchers properly so they can work even though they have singleton behavior' do
            expect(copied_matcher).not_to equal(all_matcher)
            expect(copied_matcher.matcher).not_to equal(base_matcher)
            expect([[3]]).to copied_matcher
            expect { expect([[4]]).to copied_matcher }.to fail_including("expected [4]")
          end

        end

      end
    end

    include_examples 'making a copy', :clone
    include_examples 'making a copy', :dup

    context "when using a matcher instance that memoizes state multiple times in a composed expression" do
      it "works properly in spite of the memoization" do
        expect {
          expect(["foo", "bar", "a"]).to all( have_string_length(3) )
        }.to fail
      end

      context "when passing a compound expression" do
        it "works properly in spite of the memoization" do
          expect {
            expect(["foo", "bar", "a"]).to all( have_string_length(2).or have_string_length(3) )
          }.to fail
        end
      end
    end

    context 'when the actual data does not define #each_with_index' do
      let(:actual) { 5 }

      it 'returns a failure message' do
        expect {
          expect(actual).to all(be_a(String))
        }.to fail_with("expected #{actual.inspect} to all be a kind of String, but was not iterable")
      end
    end

    context 'when the actual data does not include enumerable but defines #each_with_index' do
      let(:actual) do
        obj = Object.new
        def obj.each_with_index(&_block); [5].each_with_index { |o, i| yield(o, i) }; end
        obj
      end

      it 'passes properly' do
        expect(actual).to all(be_a(Integer))
      end

      it 'fails properly' do
        expect {
          expect(actual).to all(be_even)
        }.to fail_with(/to all be even/)
      end
    end

  end
end
