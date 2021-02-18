if (1..2).respond_to?(:cover?)
  RSpec.describe "expect(...).to cover(expected)" do
    it_behaves_like "an RSpec value matcher", :valid_value => (1..10), :invalid_value => (20..30) do
      let(:matcher) { cover(5) }
    end

    context "for a range target" do
      it "passes if target covers expected" do
        expect((1..10)).to cover(5)
      end

      it "fails if target does not cover expected" do
        expect {
          expect((1..10)).to cover(11)
        }.to fail_with("expected 1..10 to cover 11")
      end
    end
  end

  RSpec.describe "expect(...).to cover(with, multiple, args)" do
    context "for a range target" do
      it "passes if target covers all items" do
        expect((1..10)).to cover(4, 6)
      end

      it "fails if target does not cover any one of the items" do
        expect {
          expect((1..10)).to cover(4, 6, 11)
        }.to fail_with("expected 1..10 to cover 4, 6, and 11")
      end
    end
  end

  RSpec.describe "expect(...).not_to cover(expected)" do
    context "for a range target" do
      it "passes if target does not cover expected" do
        expect((1..10)).not_to cover(11)
      end

      it "fails if target covers expected" do
        expect {
          expect((1..10)).not_to cover(5)
        }.to fail_with("expected 1..10 not to cover 5")
      end
    end
  end

  RSpec.describe "expect(...).not_to cover(with, multiple, args)" do
    context "for a range target" do
      it "passes if the target does not cover any of the expected" do
        expect((1..10)).not_to cover(11, 12, 13)
      end

      it "fails if the target covers all of the expected" do
        expect {
          expect((1..10)).not_to cover(4, 6)
        }.to fail_with("expected 1..10 not to cover 4 and 6")
      end

      it "fails if the target covers some (but not all) of the expected" do
        expect {
          expect((1..10)).not_to cover(5, 11)
        }.to fail_with("expected 1..10 not to cover 5 and 11")
      end
    end
  end
end
