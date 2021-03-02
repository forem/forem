module RSpec
  module Expectations
    RSpec.describe ExpectationTarget do
      context 'when constructed via #expect' do
        it 'constructs a new instance targetting the given argument' do
          expect(expect(7).target).to eq(7)
        end

        it 'constructs a new instance targetting the given block' do
          block = lambda {}
          expect(expect(&block).target).to be(block)
        end

        it 'raises an ArgumentError when given an argument and a block' do
          expect {
            expect(7) {}
          }.to raise_error(ArgumentError)
        end

        it 'raises a wrong number of args ArgumentError when given two args' do
          expect {
            expect(1, 2)
          }.to raise_error(ArgumentError, /wrong number of arg/)
        end

        it 'raises an ArgumentError when given neither an argument nor a block' do
          expect {
            expect
          }.to raise_error(ArgumentError)
        end

        it 'can be passed nil' do
          expect(expect(nil).target).to be_nil
        end

        it 'passes a valid positive expectation' do
          expect(5).to eq(5)
        end

        it 'passes a valid negative expectation' do
          expect(5).not_to eq(4)
        end

        it 'passes a valid negative expectation with a split infinitive' do
          expect(5).to_not eq(4)
        end

        it 'fails an invalid positive expectation' do
          expect {
            expect(5).to eq(4)
          }.to fail_with(/expected: 4.*got: 5/m)
        end

        it 'fails an invalid negative expectation' do
          message = /expected 5 not to be a kind of Integer/
          expect {
            expect(5).not_to be_an(Integer)
          }.to fail_with(message)
        end

        it 'fails an invalid negative expectation with a split infinitive' do
          message = /expected 5 not to be a kind of Integer/
          expect {
            expect(5).to_not be_an(Integer)
          }.to fail_with(message)
        end

        it 'does not support operator matchers from #to' do
          expect {
            expect(3).to == 3
          }.to raise_error(ArgumentError)
        end

        it 'does not support operator matchers from #not_to' do
          expect {
            expect(3).not_to == 4
          }.to raise_error(ArgumentError)
        end
      end

      context "when passed a block" do
        it 'can be used with a block matcher' do
          expect {}.not_to raise_error
        end

        context 'when passed a value matcher' do
          not_a_block_matcher_error = /You must pass an argument rather than a block to `expect` to use the provided matcher/

          it 'raises an error that directs the user to pass an arg rather than a block' do
            expect {
              expect {}.to be_an(Object)
            }.to fail_with(not_a_block_matcher_error)

            expect {
              expect {}.not_to be_nil
            }.to fail_with(not_a_block_matcher_error)

            expect {
              expect {}.to_not be_nil
            }.to fail_with(not_a_block_matcher_error)
          end

          it 'assumes a custom matcher that does not define `supports_block_expectations?` is not a block matcher (since it is relatively rare)' do
            custom_matcher = Module.new do
              def self.matches?(_value); true; end
              def self.description; "foo"; end
            end

            expect(3).to custom_matcher # to show the custom matcher can be used as a matcher

            expect {
              expect { 3 }.to custom_matcher
            }.to fail_with(not_a_block_matcher_error)
          end

          def new_non_dsl_matcher(&method_defs)
            Module.new do
              def self.matches?(object); end
              def self.failure_message; end
              module_eval(&method_defs)
            end
          end

          it "uses the matcher's `description` in the error message" do
            custom_matcher = new_non_dsl_matcher do
              def self.supports_block_expectations?; false; end
              def self.description; "matcher-description"; end
            end

            expect {
              expect {}.to custom_matcher
            }.to fail_with(/\(matcher-description\)/)
          end

          context 'when the matcher does not define `description` (since it is an optional part of the protocol)' do
            it 'uses `inspect` in the error message instead' do
              custom_matcher = new_non_dsl_matcher do
                def self.supports_block_expectations?; false; end
                def self.inspect; "matcher-inspect"; end
              end

              expect {
                expect {}.to custom_matcher
              }.to fail_with(/\(matcher-inspect\)/)
            end
          end
        end
      end
    end
  end
end
