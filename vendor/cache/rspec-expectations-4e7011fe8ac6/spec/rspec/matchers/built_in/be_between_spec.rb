module RSpec::Matchers::BuiltIn
  RSpec.describe BeBetween do
    class SizeMatters
      include Comparable
      attr_reader :str
      def <=>(other)
        str.size <=> other.str.size
      end
      def initialize(str)
        @str = str
      end
      def inspect
        @str
      end
    end

    shared_examples "be_between" do |mode|
      it "passes if target is between min and max" do
        expect(5).to matcher(1, 10)
      end

      it "fails if target is not between min and max" do
        expect {
          # It does not go to 11
          expect(11).to matcher(1, 10)
        }.to fail_with("expected 11 to be between 1 and 10 (#{mode})")
      end

      it "works with strings" do
        expect("baz").to matcher("bar", "foo")

        expect {
          expect("foo").to matcher("bar", "baz")
        }.to fail_with("expected \"foo\" to be between \"bar\" and \"baz\" (#{mode})")
      end

      it "works with other Comparable objects" do
        expect(SizeMatters.new("--")).to matcher(SizeMatters.new("-"), SizeMatters.new("---"))

        expect {
          expect(SizeMatters.new("---")).to matcher(SizeMatters.new("-"), SizeMatters.new("--"))
        }.to fail_with("expected --- to be between - and -- (#{mode})")
      end
    end

    shared_examples "not_to be_between" do |mode|
      it "passes if target is not between min and max" do
        expect(11).not_to matcher(1, 10)
      end

      it "fails if target is between min and max" do
        expect {
          expect(5).not_to matcher(1, 10)
        }.to fail_with("expected 5 not to be between 1 and 10 (#{mode})")
      end
    end

    shared_examples "composing with other matchers" do |mode|
      it "passes when the matchers both match" do
        expect([nil, 3]).to include(matcher(2, 4), a_nil_value)
      end

      it "works with mixed types" do
        expect(["baz", Math::PI]).to include(matcher(3.1, 3.2), matcher("bar", "foo"))

        expect {
          expect(["baz", 2.14]).to include(matcher(3.1, 3.2), matcher("bar", "foo") )
        }.to fail_with("expected [\"baz\", 2.14] to include (a value between 3.1 and 3.2 (#{mode}))")
      end

      it "provides a description" do
        description = include(matcher(2, 4), an_instance_of(Float)).description
        expect(description).to eq("include (a value between 2 and 4 (#{mode})) and (an instance of Float)")
      end

      it "fails with a clear error message when the matchers do not match" do
        expect {
          expect([nil, 1]).to include(matcher(2, 4), a_nil_value)
        }.to fail_with("expected [nil, 1] to include (a value between 2 and 4 (#{mode}))")
      end
    end

    it_behaves_like "an RSpec value matcher", :valid_value => (10), :invalid_value => (11) do
      let(:matcher) { be_between(1, 10) }
    end

    describe "expect(...).to be_between(min, max) (inclusive)" do
      it_behaves_like "be_between", :inclusive do
        def matcher(min, max)
          be_between(min, max)
        end
      end

      it "is inclusive" do
        expect(1).to be_between(1, 10)
        expect(10).to be_between(1, 10)
      end

      it "indicates it was not comparable if it does not respond to `<=` and `>=`" do
        expect {
          expect(nil).to be_between(0, 10)
        }.to fail_with("expected nil to be between 0 and 10 (inclusive), but it does not respond to `<=` and `>=`")
      end
    end

    describe "expect(...).to be_between(min, max) (exclusive)" do
      it_behaves_like "be_between", :exclusive do
        def matcher(min, max)
          be_between(min, max).exclusive
        end
      end

      it "indicates it was not comparable if it does not respond to `<` and `>`" do
        expect {
          expect(nil).to be_between(0, 10).exclusive
        }.to fail_with("expected nil to be between 0 and 10 (exclusive), but it does not respond to `<` and `>`")
      end

      it "is exclusive" do
        expect { expect(1).to be_between(1, 10).exclusive }.to fail
        expect { expect(10).to be_between(1, 10).exclusive }.to fail
      end
    end

    describe "expect(...).not_to be_between(min, max) (inclusive)" do
      it_behaves_like "not_to be_between", :inclusive do
        def matcher(min, max)
          be_between(min, max)
        end
      end
    end

    describe "expect(...).not_to be_between(min, max) (exclusive)" do
      it_behaves_like "not_to be_between", :exclusive do
        def matcher(min, max)
          be_between(min, max).exclusive
        end
      end
    end

    describe "composing with other matchers (inclusive)" do
      it_behaves_like "composing with other matchers", :inclusive do
        def matcher(min, max)
          a_value_between(min, max)
        end
      end
    end

    describe "composing with other matchers (exclusive)" do
      it_behaves_like "composing with other matchers", :exclusive do
        def matcher(min, max)
          a_value_between(min, max).exclusive
        end
      end
    end
  end
end
