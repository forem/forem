module RSpec
  module Mocks
    module ArgumentMatchers
      RSpec.describe ArrayIncludingMatcher do
        it "describes itself properly" do
          expect(ArrayIncludingMatcher.new([1, 2, 3]).description).to eq "array_including(1, 2, 3)"
        end

        it "describes passed matchers" do
          description = array_including(fake_matcher(Object.new)).description

          expect(description).to include(MatcherHelpers.fake_matcher_description)
        end

        context "passing" do
          it "matches the same array" do
            expect(array_including([1, 2, 3])).to be === [1, 2, 3]
          end

          it "matches the same array, specified without square brackets" do
            expect(array_including(1, 2, 3)).to be === [1, 2, 3]
          end

          it "matches the same array, specified without square brackets" do
            expect(array_including(1, 2, 3)).to be === [1, 2, 3]
          end

          it "matches the same array, which includes nested arrays" do
            expect(array_including([1, 2], 3, 4)).to be === [[1, 2], 3, 4]
          end

          it "works with duplicates in expected" do
            expect(array_including(1, 1, 2, 3)).to be === [1, 2, 3]
          end

          it "works with duplicates in actual" do
            expect(array_including(1, 2, 3)).to be === [1, 1, 2, 3]
          end

          it "is composable with other matchers" do
            klass = Class.new
            dbl = double
            expect(dbl).to receive(:a_message).with(3, array_including(instance_of(klass)))
            dbl.a_message(3, [1, klass.new, 4])
          end

          # regression check
          it "is composable when nested" do
            expect(array_including(1, array_including(2, 3), 4)).to be === [1, [2, 3], 4]
            expect([[1, 2], 3, 4]).to match array_including(array_including(1, 2), 3, 4)
            expect([1,[1,2]]).to match array_including(1, array_including(1,2))
          end
        end

        context "failing" do
          it "fails when not all the entries in the expected are present" do
            expect(array_including(1, 2, 3, 4, 5)).not_to be === [1, 2]
          end

          it "fails when passed a composed matcher is pased and not satisfied" do
            with_unfulfilled_double do |dbl|
              expect {
                klass = Class.new
                expect(dbl).to receive(:a_message).with(3, array_including(instance_of(klass)))
                dbl.a_message(3, [1, 4])
              }.to fail_with(/expected: \(3, array_including\(an_instance_of\(\)\)\)/)
            end
          end
        end
      end
    end
  end
end
