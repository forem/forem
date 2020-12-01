RSpec.describe "expect(...).to have_sym(*args)" do
  it_behaves_like "an RSpec matcher", :valid_value => { :a => 1 },
                                      :invalid_value => {} do
    let(:matcher) { have_key(:a) }
  end

  it "passes if #has_sym?(*args) returns true" do
    expect({ :a => "A" }).to have_key(:a)
  end

  if RSpec::Support::RubyFeatures.required_kw_args_supported?
    binding.eval(<<-CODE, __FILE__, __LINE__)
    it 'supports the use of required keyword arguments' do
      thing = Class.new { def has_keyword?(keyword:); keyword == 'a'; end }
      expect(thing.new).to have_keyword(keyword: 'a')
    end
    CODE
  end

  if RSpec::Support::RubyFeatures.kw_args_supported?
    binding.eval(<<-CODE, __FILE__, __LINE__)
    it 'supports the use of optional keyword arguments' do
      thing = Class.new { def has_keyword?(keyword: 'b'); keyword == 'a'; end }
      expect(thing.new).to have_keyword(keyword: 'a')
    end
    CODE
  end

  it "fails if #has_sym?(*args) returns false" do
    expect {
      expect({ :b => "B" }).to have_key(:a)
    }.to fail_with('expected `{:b=>"B"}.has_key?(:a)` to return true, got false')
  end

  obj_with_block_method = Object.new
  def obj_with_block_method.has_some_stuff?; yield; end

  it 'forwards the given `{ }` block on to the `has_xyz?` method' do
    expect(obj_with_block_method).to have_some_stuff { true }
    expect(obj_with_block_method).to_not have_some_stuff { false }
  end

  it 'forwards the given `do..end` block on to the `has_xyz?` method' do
    expect(obj_with_block_method).to have_some_stuff do
      true
    end

    expect(obj_with_block_method).to_not have_some_stuff do
      false
    end
  end

  it 'favors a curly brace block over a do...end one since it binds to the matcher method' do
    expect(obj_with_block_method).to have_some_stuff { true } do
      false
    end

    expect(obj_with_block_method).not_to have_some_stuff { false } do
      true
    end
  end

  it 'does not include any args in the failure message if no args were given to the matcher' do
    o = Object.new
    def o.has_some_stuff?; false; end
    expect {
      expect(o).to have_some_stuff
    }.to fail_with("expected `#{o.inspect}.has_some_stuff?` to return true, got false")
  end

  it 'includes multiple args in the failure message if multiple args were given to the matcher' do
    o = Object.new
    def o.has_some_stuff?(*_); false; end
    expect {
      expect(o).to have_some_stuff(:a, 7, "foo")
    }.to fail_with(%Q{expected `#{o.inspect}.has_some_stuff?(:a, 7, "foo")` to return true, got false})
  end

  it "fails if #has_sym?(*args) returns nil" do
    klass = Class.new do
      def has_foo?
      end
    end
    expect {
      expect(klass.new).to have_foo
    }.to fail_with(/expected `.*\.has_foo\?` to return true, got nil/)
  end

  it 'fails if #has_sym?(*args) is private' do
    klass = Class.new do
      private
      def has_foo?
        true
      end
    end
    expect { expect(klass.new).to have_foo }.to fail_with(/private/)
  end

  it "fails if target does not respond to #has_sym?" do
    expect {
      expect(Object.new).to have_key(:a)
    }.to fail_including('to respond to `has_key?`')
  end

  it "reraises an exception thrown in #has_sym?(*args)" do
    o = Object.new
    def o.has_sym?(*_args)
      raise "Funky exception"
    end
    expect {
      expect(o).to have_sym(:foo)
    }.to raise_error("Funky exception")
  end

  it 'allows composable aliases to be defined' do
    RSpec::Matchers.alias_matcher :an_object_having_sym, :have_sym
    o = Object.new
    def o.has_sym?(sym); sym == :foo; end

    expect(o).to an_object_having_sym(:foo)
    expect(o).not_to an_object_having_sym(:bar)

    expect(an_object_having_sym(:foo).description).to eq("an object having sym :foo")
  end

  it 'composes gracefully' do
    RSpec::Matchers.alias_matcher :an_object_having_foo, :have_foo

    expect([
      double,
      double(:has_foo? => false),
      double(:has_foo? => true),
    ]).to include an_object_having_foo
  end
end

RSpec.describe "expect(...).not_to have_sym(*args)" do
  it "passes if #has_sym?(*args) returns false" do
    expect({ :a => "A" }).not_to have_key(:b)
  end

  context "when strict_predicate_matchers is set to true" do
    it "fails when #has_sym? returns nil" do
      actual = double("actual", :has_foo? => nil)
      expect {
        expect(actual).not_to have_foo
      }.to fail_with("expected `#{actual.inspect}.has_foo?` to return false, got nil")
    end
  end

  context "when strict_predicate_matchers is set to false" do
    around do |example|
      RSpec::Expectations.configuration.strict_predicate_matchers = false
      example.run
      RSpec::Expectations.configuration.strict_predicate_matchers = true
    end

    it "passes if #has_sym?(*args) returns nil" do
      actual = double("actual", :has_foo? => nil)
      expect(actual).not_to have_foo
    end
  end

  it "fails if #has_sym?(*args) returns true" do
    expect {
      expect({ :a => "A" }).not_to have_key(:a)
    }.to fail_with('expected `{:a=>"A"}.has_key?(:a)` to return false, got true')
  end

  it "fails if target does not respond to #has_sym?" do
    expect {
      expect(Object.new).not_to have_key(:a)
    }.to fail_including('to respond to `has_key?`')
  end

  it "reraises an exception thrown in #has_sym?(*args)" do
    o = Object.new
    def o.has_sym?(*_args)
      raise "Funky exception"
    end
    expect {
      expect(o).not_to have_sym(:foo)
    }.to raise_error("Funky exception")
  end

  it 'does not include any args in the failure message if no args were given to the matcher' do
    o = Object.new
    def o.has_some_stuff?; true; end
    expect {
      expect(o).not_to have_some_stuff
    }.to fail_with("expected `#{o.inspect}.has_some_stuff?` to return false, got true")
  end

  it 'includes multiple args in the failure message if multiple args were given to the matcher' do
    o = Object.new
    def o.has_some_stuff?(*_); true; end
    expect {
      expect(o).not_to have_some_stuff(:a, 7, "foo")
    }.to fail_with(%Q{expected `#{o.inspect}.has_some_stuff?(:a, 7, "foo")` to return false, got true})
  end
end

RSpec.describe "has" do
  it "works when the target implements #send" do
    o = { :a => "A" }
    def o.send(*_args); raise "DOH! Library developers shouldn't use #send!" end
    expect {
      expect(o).to have_key(:a)
    }.not_to raise_error
  end
end
