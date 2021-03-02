module RSpec::Matchers::BuiltIn
  RSpec.describe ThrowSymbol do
    it_behaves_like "an RSpec block-only matcher" do
      def valid_block
        throw :foo
      end
      def invalid_block
      end
      let(:matcher) { throw_symbol(:foo) }
    end

    describe "with no args" do
      before(:example) { @matcher = throw_symbol }

      it "matches if any Symbol is thrown" do
        expect(@matcher.matches?(lambda { throw :sym })).to be_truthy
      end
      it "matches if any Symbol is thrown with an arg" do
        expect(@matcher.matches?(lambda { throw :sym, "argument" })).to be_truthy
      end
      it "does not match if no Symbol is thrown" do
        expect(@matcher.matches?(lambda {})).to be_falsey
      end
      it "provides a failure message" do
        @matcher.matches?(lambda {})
        expect(@matcher.failure_message).to eq "expected a Symbol to be thrown, got nothing"
      end
      it "provides a negative failure message" do
        @matcher.matches?(lambda { throw :sym })
        expect(@matcher.failure_message_when_negated).to eq "expected no Symbol to be thrown, got :sym"
      end
    end

    describe "with a symbol" do
      before(:example) { @matcher = throw_symbol(:sym) }

      it "matches if correct Symbol is thrown" do
        expect(@matcher.matches?(lambda { throw :sym })).to be_truthy
      end
      it "matches if correct Symbol is thrown with an arg" do
        expect(@matcher.matches?(lambda { throw :sym, "argument" })).to be_truthy
      end
      it "does not match if no Symbol is thrown" do
        expect(@matcher.matches?(lambda {})).to be_falsey
      end
      it "does not match if correct Symbol is thrown" do
        expect(@matcher.matches?(lambda { throw :other_sym })).to be_falsey
      end
      it "provides a failure message when no Symbol is thrown" do
        @matcher.matches?(lambda {})
        expect(@matcher.failure_message).to eq "expected :sym to be thrown, got nothing"
      end
      it "provides a failure message when wrong Symbol is thrown" do
        @matcher.matches?(lambda { throw :other_sym })
        expect(@matcher.failure_message).to eq "expected :sym to be thrown, got :other_sym"
      end
      it "provides a negative failure message" do
        @matcher.matches?(lambda { throw :sym })
        expect(@matcher.failure_message_when_negated).to eq "expected :sym not to be thrown, got :sym"
      end
      it "only matches NameErrors raised by uncaught throws" do
        expect {
          expect(@matcher.matches?(lambda { sym })).to be_falsey
        }.to raise_error(NameError)
      end
    end

    describe "with a symbol and an arg" do
      before(:example) { @matcher = throw_symbol(:sym, "a") }

      it "matches if correct Symbol and args are thrown" do
        expect(@matcher.matches?(lambda { throw :sym, "a" })).to be_truthy
      end
      it "does not match if nothing is thrown" do
        expect(@matcher.matches?(lambda {})).to be_falsey
      end
      it "does not match if other Symbol is thrown" do
        expect(@matcher.matches?(lambda { throw :other_sym, "a" })).to be_falsey
      end
      it "does not match if no arg is thrown" do
        expect(@matcher.matches?(lambda { throw :sym })).to be_falsey
      end
      it "does not match if wrong arg is thrown" do
        expect(@matcher.matches?(lambda { throw :sym, "b" })).to be_falsey
      end
      it "provides a failure message when no Symbol is thrown" do
        @matcher.matches?(lambda {})
        expect(@matcher.failure_message).to eq 'expected :sym with "a" to be thrown, got nothing'
      end
      it "provides a failure message when wrong Symbol is thrown" do
        @matcher.matches?(lambda { throw :other_sym })
        expect(@matcher.failure_message).to eq 'expected :sym with "a" to be thrown, got :other_sym'
      end
      it "provides a failure message when wrong arg is thrown" do
        @matcher.matches?(lambda { throw :sym, "b" })
        expect(@matcher.failure_message).to eq 'expected :sym with "a" to be thrown, got :sym with "b"'
      end
      it "provides a failure message when no arg is thrown" do
        @matcher.matches?(lambda { throw :sym })
        expect(@matcher.failure_message).to eq 'expected :sym with "a" to be thrown, got :sym with no argument'
      end
      it "provides a negative failure message" do
        @matcher.matches?(lambda { throw :sym })
        expect(@matcher.failure_message_when_negated).to eq 'expected :sym with "a" not to be thrown, got :sym with no argument'
      end
      it "only matches NameErrors raised by uncaught throws" do
        expect {
          expect(@matcher.matches?(lambda { sym })).to be_falsey
        }.to raise_error(NameError)
      end
      it "raises other errors" do
        expect {
          @matcher.matches?(lambda { raise "Boom" })
        }.to raise_error(/Boom/)
      end
    end

    describe "composing with other matchers" do
      it 'passes when the matcher matches the thrown arg' do
        expect {
          throw :foo, "bar"
        }.to throw_symbol(:foo, a_string_matching(/bar/))
      end

      it 'fails when the matcher does not match the thrown arg' do
        expect {
          expect { throw :foo, "bar" }.to throw_symbol(:foo, a_string_matching(/foo/))
        }.to fail_with('expected :foo with a string matching /foo/ to be thrown, got :foo with "bar"')
      end

      it 'provides a description' do
        description = throw_symbol(:foo, a_string_matching(/bar/)).description
        expect(description).to eq("throw :foo with a string matching /bar/")
      end
    end
  end
end
