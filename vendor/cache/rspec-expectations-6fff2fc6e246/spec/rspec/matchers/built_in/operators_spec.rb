class MethodOverrideObject
  def method
    :foo
  end
end

class MethodMissingObject < Struct.new(:original)
  undef ==

  def method_missing(name, *args, &block)
    original.__send__ name, *args, &block
  end
end

RSpec.describe "operator matchers", :uses_should do
  describe "should ==" do
    it "delegates message to target" do
      subject = "apple".dup
      expect(subject).to receive(:==).with("apple").and_return(true)
      subject.should == "apple"
    end

    it "returns true on success" do
      subject = "apple"
      (subject.should == "apple").should be_truthy
    end

    it "fails when target.==(actual) returns false" do
      subject = "apple"
      expect(RSpec::Expectations).to receive(:fail_with).with(%{expected: "orange"\n     got: "apple" (using ==)}, "orange", "apple")
      subject.should == "orange"
    end

    it "works when #method is overriden" do
      myobj = MethodOverrideObject.new
      expect {
        myobj.should == myobj
      }.to_not raise_error
    end

    it "works when implemented via method_missing" do
      obj = Object.new

      myobj = MethodMissingObject.new(obj)
      (myobj.should == obj).nil? # just to avoid `useless use of == in void context` warning
      myobj.should_not == Object.new
    end
  end

  describe "unsupported operators", :if => RUBY_VERSION.to_f == 1.9 do
    it "raises an appropriate error for should != expected" do
      expect {
        "apple".should != "pear"
      }.to raise_error(/does not support `should != expected`.  Use `should_not == expected`/)
    end

    it "raises an appropriate error for should_not != expected" do
      expect {
        "apple".should_not != "pear"
      }.to raise_error(/does not support `should_not != expected`.  Use `should == expected`/)
    end

    it "raises an appropriate error for should !~ expected" do
      expect {
        "apple".should !~ /regex/
      }.to raise_error(/does not support `should !~ expected`.  Use `should_not =~ expected`/)
    end

    it "raises an appropriate error for should_not !~ expected" do
      expect {
        "apple".should_not !~ /regex/
      }.to raise_error(/does not support `should_not !~ expected`.  Use `should =~ expected`/)
    end
  end

  describe "should_not ==" do
    it "delegates message to target" do
      subject = "orange".dup
      expect(subject).to receive(:==).with("apple").and_return(false)
      subject.should_not == "apple"
    end

    it "returns true on success" do
      subject = "apple"
      (subject.should_not == "orange").should be_falsey
    end

    it "fails when target.==(actual) returns false" do
      subject = "apple"
      expect(RSpec::Expectations).to receive(:fail_with).with(%(expected not: == "apple"\n         got:    "apple"), "apple", "apple")
      subject.should_not == "apple"
    end
  end

  describe "should ===" do
    it "delegates message to target" do
      subject = "apple".dup
      expect(subject).to receive(:===).with("apple").and_return(true)
      subject.should === "apple"
    end

    it "fails when target.===(actual) returns false" do
      subject = "apple".dup
      expect(subject).to receive(:===).with("orange").and_return(false)
      expect(RSpec::Expectations).to receive(:fail_with).with(%{expected: "orange"\n     got: "apple" (using ===)}, "orange", "apple")
      subject.should === "orange"
    end
  end

  describe "should_not ===" do
    it "delegates message to target" do
      subject = "orange".dup
      expect(subject).to receive(:===).with("apple").and_return(false)
      subject.should_not === "apple"
    end

    it "fails when target.===(actual) returns false" do
      subject = "apple".dup
      expect(subject).to receive(:===).with("apple").and_return(true)
      expect(RSpec::Expectations).to receive(:fail_with).with(%(expected not: === "apple"\n         got:     "apple"), "apple", "apple")
      subject.should_not === "apple"
    end
  end

  describe "should =~" do
    it "delegates message to target" do
      subject = "foo".dup
      expect(subject).to receive(:=~).with(/oo/).and_return(true)
      subject.should =~ /oo/
    end

    it "fails when target.=~(actual) returns false" do
      subject = "fu".dup
      expect(subject).to receive(:=~).with(/oo/).and_return(false)
      expect(RSpec::Expectations).to receive(:fail_with).with(%{expected: /oo/\n     got: "fu" (using =~)}, /oo/, "fu")
      subject.should =~ /oo/
    end
  end

  describe "should_not =~" do
    it "delegates message to target" do
      subject = "fu".dup
      expect(subject).to receive(:=~).with(/oo/).and_return(false)
      subject.should_not =~ /oo/
    end

    it "fails when target.=~(actual) returns false" do
      subject = "foo".dup
      expect(subject).to receive(:=~).with(/oo/).and_return(true)
      expect(RSpec::Expectations).to receive(:fail_with).with(%(expected not: =~ /oo/\n         got:    "foo"), /oo/, "foo")
      subject.should_not =~ /oo/
    end
  end

  describe "should >" do
    it "passes if > passes" do
      4.should > 3
    end

    it "fails if > fails" do
      expect(RSpec::Expectations).to receive(:fail_with).with("expected: > 5\n     got:   4", 5, 4)
      4.should > 5
    end
  end

  describe "should >=" do
    it "passes if actual == expected" do
      4.should >= 4
    end

    it "passes if actual > expected" do
      4.should >= 3
    end

    it "fails if > fails" do
      expect(RSpec::Expectations).to receive(:fail_with).with("expected: >= 5\n     got:    4", 5, 4)
      4.should >= 5
    end
  end

  describe "should <" do
    it "passes if < passes" do
      4.should < 5
    end

    it "fails if > fails" do
      expect(RSpec::Expectations).to receive(:fail_with).with("expected: < 3\n     got:   4", 3, 4)
      4.should < 3
    end
  end

  describe "should <=" do
    it "passes if actual == expected" do
      4.should <= 4
    end

    it "passes if actual < expected" do
      4.should <= 5
    end

    it "fails if > fails" do
      expect(RSpec::Expectations).to receive(:fail_with).with("expected: <= 3\n     got:    4", 3, 4)
      4.should <= 3
    end
  end

  describe "OperatorMatcher registry" do
    let(:custom_klass) { Class.new }
    let(:custom_subklass) { Class.new(custom_klass) }

    after {
      RSpec::Matchers::BuiltIn::OperatorMatcher.unregister(custom_klass, "=~")
    }

    it "allows operator matchers to be registered for classes" do
      RSpec::Matchers::BuiltIn::OperatorMatcher.register(custom_klass, "=~", RSpec::Matchers::BuiltIn::Match)
      expect(RSpec::Matchers::BuiltIn::OperatorMatcher.get(custom_klass, "=~")).to eq(RSpec::Matchers::BuiltIn::Match)
    end

    it "considers ancestors when finding an operator matcher" do
      RSpec::Matchers::BuiltIn::OperatorMatcher.register(custom_klass, "=~", RSpec::Matchers::BuiltIn::Match)
      expect(RSpec::Matchers::BuiltIn::OperatorMatcher.get(custom_subklass, "=~")).to eq(RSpec::Matchers::BuiltIn::Match)
    end

    it "returns nil if there is no matcher registered for a class" do
      expect(RSpec::Matchers::BuiltIn::OperatorMatcher.get(custom_klass, "=~")).to be_nil
    end
  end

  describe RSpec::Matchers::BuiltIn::PositiveOperatorMatcher do
    it "works when the target has implemented #send" do
      o = Object.new
      def o.send(*_args); raise "DOH! Library developers shouldn't use #send!" end
      expect {
        o.should == o
      }.not_to raise_error
    end
  end

  describe RSpec::Matchers::BuiltIn::NegativeOperatorMatcher do
    it "works when the target has implemented #send" do
      o = Object.new
      def o.send(*_args); raise "DOH! Library developers shouldn't use #send!" end
      expect {
        o.should_not == :foo
      }.not_to raise_error
    end
  end
end
