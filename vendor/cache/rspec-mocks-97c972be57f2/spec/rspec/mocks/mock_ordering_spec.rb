module RSpec
  module Mocks
    RSpec.describe "ordering" do
      before { @double = double("test double") }
      after  { reset @double }

      it "passes when messages are received in order" do
        expect(@double).to receive(:one).ordered
        expect(@double).to receive(:two).ordered
        expect(@double).to receive(:three).ordered
        @double.one
        @double.two
        @double.three
      end

      it "passes when messages are received in order" do
        allow(@double).to receive(:something)
        expect(@double).to receive(:one).ordered
        expect(@double).to receive(:two).ordered
        expect(@double).to receive(:three).at_least(:once).ordered
        @double.one
        @double.two
        @double.three
        @double.three
      end

      it "passes when messages are received in order across objects" do
        a = double("a")
        b = double("b")
        expect(a).to receive(:one).ordered
        expect(b).to receive(:two).ordered
        expect(a).to receive(:three).ordered
        a.one
        b.two
        a.three
      end

      it "fails when messages are received out of order (2nd message 1st)" do
        expect(@double).to receive(:one).ordered
        expect(@double).to receive(:two).ordered
        expect {
          @double.two
        }.to fail_with "#<Double \"test double\"> received :two out of order"
      end

      it "fails when messages are received out of order (3rd message 1st)" do
        expect(@double).to receive(:one).ordered
        expect(@double).to receive(:two).ordered
        expect(@double).to receive(:three).ordered
        @double.one
        expect {
          @double.three
        }.to fail_with "#<Double \"test double\"> received :three out of order"
      end

      it "fails when messages are received out of order (3rd message 2nd)" do
        expect(@double).to receive(:one).ordered
        expect(@double).to receive(:two).ordered
        expect(@double).to receive(:three).ordered
        @double.one
        expect {
          @double.three
        }.to fail_with "#<Double \"test double\"> received :three out of order"
      end

      it "fails when messages are out of order across objects" do
        a = double("test double")
        b = double("another test double")
        expect(a).to receive(:one).ordered
        expect(b).to receive(:two).ordered
        expect(a).to receive(:three).ordered
        a.one
        expect {
          a.three
        }.to fail_with "#<Double \"test double\"> received :three out of order"
        reset a
        reset b
      end

      it "ignores order of non ordered messages" do
        expect(@double).to receive(:ignored_0)
        expect(@double).to receive(:ordered_1).ordered
        expect(@double).to receive(:ignored_1)
        expect(@double).to receive(:ordered_2).ordered
        expect(@double).to receive(:ignored_2)
        expect(@double).to receive(:ignored_3)
        expect(@double).to receive(:ordered_3).ordered
        expect(@double).to receive(:ignored_4)
        @double.ignored_3
        @double.ordered_1
        @double.ignored_0
        @double.ordered_2
        @double.ignored_4
        @double.ignored_2
        @double.ordered_3
        @double.ignored_1
        verify @double
      end

      it "supports duplicate messages" do
        expect(@double).to receive(:a).ordered
        expect(@double).to receive(:b).ordered
        expect(@double).to receive(:a).ordered

        @double.a
        @double.b
        @double.a
      end
    end
  end
end
