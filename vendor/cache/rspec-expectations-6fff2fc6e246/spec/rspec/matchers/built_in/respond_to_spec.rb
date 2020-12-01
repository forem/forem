RSpec.describe "expect(...).to respond_to(:sym)" do
  it_behaves_like "an RSpec matcher", :valid_value => "s", :invalid_value => 5 do
    let(:matcher) { respond_to(:upcase) }
  end

  it "passes if target responds to :sym" do
    expect(Object.new).to respond_to(:methods)
  end

  it "passes if target responds to :sym but does not implement method" do
    # This simulates a behaviour of Rails, see #1162.
    klass = Class.new { def respond_to?(_); true; end }
    expect(klass.new).to respond_to(:my_method)
  end

  it "fails if target does not respond to :sym" do
    expect {
      expect("this string").to respond_to(:some_method)
    }.to fail_with('expected "this string" to respond to :some_method')
  end
end

RSpec.describe "expect(...).to respond_to(:sym).with(1).argument" do
  it "passes if target responds to :sym with 1 arg" do
    obj = Object.new
    def obj.foo(arg); end
    expect(obj).to respond_to(:foo).with(1).argument
  end

  it "passes if target responds to any number of arguments" do
    obj = Object.new
    def obj.foo(*args); end
    expect(obj).to respond_to(:foo).with(1).argument
  end

  it "passes if target responds to one or more arguments" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect(obj).to respond_to(:foo).with(1).argument
  end

  it "verifes the method signature of new as if it was initialize" do
    klass = Class.new { def initialize(a, b); end; }
    expect(klass).to respond_to(:new).with(2).arguments
  end

  it "fails if target does not respond to :sym" do
    obj = Object.new
    expect {
      expect(obj).to respond_to(:some_method).with(1).argument
    }.to fail_with(/expected .* to respond to :some_method/)
  end

  it "fails if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect {
      expect(obj).to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1 argument/)
  end

  it "fails if :sym expects 2 args" do
    obj = Object.new
    def obj.foo(arg, arg2); end
    expect {
      expect(obj).to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1 argument/)
  end

  it "fails if :sym expects 2 or more args" do
    obj = Object.new
    def obj.foo(arg, arg2, *args); end
    expect {
      expect(obj).to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1 argument/)
  end

  it "fails if the method signature of initialize does not match" do
    klass = Class.new { def initialize(a, b); end; }
    expect {
      expect(klass).to respond_to(:new).with(1).arguments
    }.to fail_with(/expected #<Class.*> to respond to :new with 1 argument/)
  end

  it "still works if target has overridden the method method" do
    obj = Object.new
    def obj.method; end
    def obj.other_method(arg); end
    expect(obj).to respond_to(:other_method).with(1).argument
  end

  it "warns that the subject does not have the implementation required when method does not exist" do
    # This simulates a behaviour of Rails, see #1162.
    klass = Class.new { def respond_to?(_); true; end }
    expect {
      expect(klass.new).to respond_to(:my_method).with(0).arguments
    }.to raise_error(ArgumentError)
  end
end

RSpec.describe "expect(...).to respond_to(:new)" do
  context "with no tampering" do
    it "will validate new as if it was initialize" do
      klass = Class.new { def initialize(a, b, c); end }
      expect(klass).not_to respond_to(:new).with(2).arguments
      expect(klass).to respond_to(:new).with(3).arguments
    end
  end

  context "on a class that has redefined `new`" do
    it "uses the method signature of the redefined `new` for arg verification" do
      klass = Class.new { def self.new(a); end }
      expect(klass).to respond_to(:new).with(1).argument
      expect {
        expect(klass).to respond_to(:new).with(2).arguments
      }.to fail_with(/expected #<Class.*> to respond to :new with 2 arguments/)
      expect {
        expect(klass).to_not respond_to(:new).with(1).argument
      }.to fail_with(/expected #<Class.*> not to respond to :new with 1 argument/)
    end
  end

  context "on a class that has undefined `new`" do
    it "will not respond to new" do
      klass =
        Class.new do
          class << self
            undef new
          end
        end

      expect {
        expect(klass).to respond_to(:new)
      }.to fail_with(/expected .* to respond to :new/)
    end
  end

  context "on a class with a private `new`" do
    it "will not respond to new" do
      klass = Class.new { private_class_method :new; def initialize(a, b, c); end }
      expect(klass).not_to respond_to(:new)
    end
  end
end

RSpec.describe "expect(...).to respond_to(message1, message2)" do
  it "passes if target responds to both messages" do
    expect(Object.new).to respond_to('methods', 'inspect')
  end

  it "fails if target does not respond to first message" do
    expect {
      expect(Object.new).to respond_to('method_one', 'inspect')
    }.to fail_with(/expected #<Object:.*> to respond to "method_one"/)
  end

  it "fails if target does not respond to second message" do
    expect {
      expect(Object.new).to respond_to('inspect', 'method_one')
    }.to fail_with(/expected #<Object:.*> to respond to "method_one"/)
  end

  it "fails if target does not respond to either message" do
    expect {
      expect(Object.new).to respond_to('method_one', 'method_two')
    }.to fail_with(/expected #<Object:.*> to respond to "method_one", "method_two"/)
  end
end

RSpec.describe "expect(...).to respond_to(:sym).with(2).arguments" do
  it "passes if target responds to :sym with 2 args" do
    obj = Object.new
    def obj.foo(a1, a2); end
    expect(obj).to respond_to(:foo).with(2).arguments
  end

  it "passes if target responds to any number of arguments" do
    obj = Object.new
    def obj.foo(*args); end
    expect(obj).to respond_to(:foo).with(2).arguments
  end

  it "passes if target responds to one or more arguments" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect(obj).to respond_to(:foo).with(2).arguments
  end

  it "passes if target responds to two or more arguments" do
    obj = Object.new
    def obj.foo(a, b, *args); end
    expect(obj).to respond_to(:foo).with(2).arguments
  end

  it "fails if target does not respond to :sym" do
    obj = Object.new
    expect {
      expect(obj).to respond_to(:some_method).with(2).arguments
    }.to fail_with(/expected .* to respond to :some_method/)
  end

  it "fails if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect {
      expect(obj).to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 2 arguments/)
  end

  it "fails if :sym expects 1 args" do
    obj = Object.new
    def obj.foo(arg); end
    expect {
      expect(obj).to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 2 arguments/)
  end

  it "fails if :sym expects 3 or more args" do
    obj = Object.new
    def obj.foo(arg, arg2, arg3, *args); end
    expect {
      expect(obj).to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 2 arguments/)
  end
end

RSpec.describe "expect(...).to respond_to(:sym).with(1..2).arguments" do
  it "passes if target responds to any number of arguments" do
    obj = Object.new
    def obj.foo(*args); end
    expect(obj).to respond_to(:foo).with(1..2).arguments
  end

  it "passes if target responds to one or more arguments" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect(obj).to respond_to(:foo).with(1..2).arguments
  end

  it "passes if target responds to one or two arguments" do
    obj = Object.new
    def obj.foo(a, b=nil); end
    expect(obj).to respond_to(:foo).with(1..2).arguments
  end

  it "passes if target responds to one to three arguments" do
    obj = Object.new
    def obj.foo(a, b=nil, c=nil); end
    expect(obj).to respond_to(:foo).with(1..2).arguments
  end

  it "passes if target is new and initialize reponds to arguments" do
    klass = Class.new { def initialize(arg, arg2=nil, arg3=nil); end }
    expect(klass).to respond_to(:new).with(1..2).arguments
  end

  it "fails if target does not respond to :sym" do
    obj = Object.new
    expect {
      expect(obj).to respond_to(:some_method).with(1..2).arguments
    }.to fail_with(/expected .* to respond to :some_method/)
  end

  it "fails if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect {
      expect(obj).to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1..2 arguments/)
  end

  it "fails if :sym expects 1 args" do
    obj = Object.new
    def obj.foo(arg); end
    expect {
      expect(obj).to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1..2 arguments/)
  end

  it "fails if :sym expects 2 args" do
    obj = Object.new
    def obj.foo(a, b); end
    expect {
      expect(obj).to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1..2 arguments/)
  end

  it "fails if :sym expects 3 or more args" do
    obj = Object.new
    def obj.foo(arg, arg2, arg3, *args); end
    expect {
      expect(obj).to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected #<Object.*> to respond to :foo with 1..2 arguments/)
  end

  it "fails when new unless initialize matches the signature" do
    klass = Class.new { def initialize(arg, arg2, arg3, *args); end }
    expect {
      expect(klass).to respond_to(:new).with(1..2).arguments
    }.to fail_with(/expected #<Class.*> to respond to :new with 1..2 arguments/)
  end
end

RSpec.describe "expect(...).to respond_to(:sym).with_unlimited_arguments" do
  it "passes if target responds to any number of arguments" do
    obj = Object.new
    def obj.foo(*args); end
    expect(obj).to respond_to(:foo).with_unlimited_arguments
  end

  it "passes if target responds to a minimum number of arguments" do
    obj = Object.new
    def obj.foo(arg, arg2, arg3, *args); end
    expect(obj).to respond_to(:foo).with(3).arguments.and_unlimited_arguments
  end

  it "passes when target is new and initialize responds to any number of aguments" do
    # note we can't use the metaobject definition for initialize
    klass_2 = Class.new { def initialize(*args); end }
    expect(klass_2).to respond_to(:new).with_unlimited_arguments
  end

  it "fails if target does not respond to :sym" do
    obj = Object.new
    expect {
      expect(obj).to respond_to(:some_method).with_unlimited_arguments
    }.to fail_with(/expected .* to respond to :some_method/)
  end

  it "fails if :sym expects a minimum number of arguments" do
    obj = Object.new
    def obj.some_method(arg, arg2, arg3, *args); end
    expect {
      expect(obj).to respond_to(:some_method).with_unlimited_arguments
    }.to fail_with(/expected .* to respond to :some_method with unlimited arguments/)
  end

  it "fails if :sym expects a limited number of arguments" do
    obj = Object.new
    def obj.some_method(arg); end
    expect {
      expect(obj).to respond_to(:some_method).with_unlimited_arguments
    }.to fail_with(/expected .* to respond to :some_method with unlimited arguments/)
  end

  it "fails when target is new and initialize responds to a set number of arguments" do
    klass = Class.new { def initialize(a); end }
    expect {
      expect(klass).to respond_to(:new).with_unlimited_arguments
    }.to fail_with(/expected .* to respond to :new with unlimited arguments/)
  end
end

RSpec.describe "expect(...).not_to respond_to(:sym)" do
  it "passes if target does not respond to :sym" do
    expect(Object.new).not_to respond_to(:some_method)
  end

  it "fails if target responds to :sym" do
    expect {
      expect(Object.new).not_to respond_to(:methods)
    }.to fail_with(/expected #<Object:.*> not to respond to :methods/)
  end
end

RSpec.describe "expect(...).not_to respond_to(:sym).with(1).argument" do
  it "fails if target responds to :sym with 1 arg" do
    obj = Object.new
    def obj.foo(arg); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object:.*> not to respond to :foo with 1 argument/)
  end

  it "fails if target responds to :sym with any number of args" do
    obj = Object.new
    def obj.foo(*args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object:.*> not to respond to :foo with 1 argument/)
  end

  it "fails if target responds to :sym with one or more args" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1).argument
    }.to fail_with(/expected #<Object:.*> not to respond to :foo with 1 argument/)
  end

  it "will fail when target is new and initialize matches the argument signature" do
    klass = Class.new { def initialize(a); end }
    expect {
      expect(klass).to_not respond_to(:new).with(1).argument
    }.to fail_with(/not to respond to :new with 1 argument/)
  end

  it "passes if target does not respond to :sym" do
    obj = Object.new
    expect(obj).not_to respond_to(:some_method).with(1).argument
  end

  it "passes if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect(obj).not_to respond_to(:foo).with(1).argument
  end

  it "passes if :sym expects 2 args" do
    obj = Object.new
    def obj.foo(arg, arg2); end
    expect(obj).not_to respond_to(:foo).with(1).argument
  end

  it "passes if :sym expects 2 or more args" do
    obj = Object.new
    def obj.foo(arg, arg2, *args); end
    expect(obj).not_to respond_to(:foo).with(1).argument
  end

  it "will pass when target is new and initialize does not matches the argument signature" do
    klass = Class.new { def initialize(a, b); end }
    expect(klass).to_not respond_to(:new).with(1).argument
  end
end

RSpec.describe "expect(...).not_to respond_to(message1, message2)" do
  it "passes if target does not respond to either message1 or message2" do
    expect(Object.new).not_to respond_to(:some_method, :some_other_method)
  end

  it "fails if target responds to message1 but not message2" do
    expect {
      expect(Object.new).not_to respond_to(:object_id, :some_method)
    }.to fail_with(/expected #<Object:.*> not to respond to :object_id/)
  end

  it "fails if target responds to message2 but not message1" do
    expect {
      expect(Object.new).not_to respond_to(:some_method, :object_id)
    }.to fail_with(/expected #<Object:.*> not to respond to :object_id/)
  end

  it "fails if target responds to both message1 and message2" do
    expect {
      expect(Object.new).not_to respond_to(:class, :object_id)
    }.to fail_with(/expected #<Object:.*> not to respond to :class, :object_id/)
  end
end

RSpec.describe "expect(...).not_to respond_to(:sym).with(2).arguments" do
  it "fails if target responds to :sym with 2 args" do
    obj = Object.new
    def obj.foo(a1, a2); end
    expect {
      expect(obj).not_to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 2 arguments/)
  end

  it "fails if target responds to :sym with any number args" do
    obj = Object.new
    def obj.foo(*args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 2 arguments/)
  end

  it "fails if target responds to :sym with one or more args" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 2 arguments/)
  end

  it "fails if target responds to :sym with two or more args" do
    obj = Object.new
    def obj.foo(a, b, *args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 2 arguments/)
  end

  it "passes if target does not respond to :sym" do
    obj = Object.new
    expect(obj).not_to respond_to(:some_method).with(2).arguments
  end

  it "passes if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect(obj).not_to respond_to(:foo).with(2).arguments
  end

  it "passes if :sym expects 2 args" do
    obj = Object.new
    def obj.foo(arg); end
    expect(obj).not_to respond_to(:foo).with(2).arguments
  end

  it "passes if :sym expects 3 or more args" do
    obj = Object.new
    def obj.foo(a, b, c, *arg); end
    expect(obj).not_to respond_to(:foo).with(2).arguments
  end
end

RSpec.describe "expect(...).not_to respond_to(:sym).with(1..2).arguments" do
  it "fails if target responds to :sym with one or two args" do
    obj = Object.new
    def obj.foo(a1, a2=nil); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 1..2 arguments/)
  end

  it "fails if target responds to :sym with any number args" do
    obj = Object.new
    def obj.foo(*args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 1..2 arguments/)
  end

  it "fails if target responds to :sym with one or more args" do
    obj = Object.new
    def obj.foo(a, *args); end
    expect {
      expect(obj).not_to respond_to(:foo).with(1..2).arguments
    }.to fail_with(/expected .* not to respond to :foo with 1..2 arguments/)
  end

  it "will fail when target is new and initialize matches the argument signature" do
    klass = Class.new { def initialize(a, *args); end }
    expect {
      expect(klass).to_not respond_to(:new).with(1..2).argument
    }.to fail_with(/not to respond to :new with 1..2 argument/)
  end

  it "passes if target does not respond to :sym" do
    obj = Object.new
    expect(obj).not_to respond_to(:some_method).with(1..2).arguments
  end

  it "passes if :sym expects 0 args" do
    obj = Object.new
    def obj.foo; end
    expect(obj).not_to respond_to(:foo).with(1..2).arguments
  end

  it "passes if :sym expects 1 arg" do
    obj = Object.new
    def obj.foo(arg); end
    expect(obj).not_to respond_to(:foo).with(1..2).arguments
  end

  it "passes if :sym expects 2 args" do
    obj = Object.new
    def obj.foo(a, b); end
    expect(obj).not_to respond_to(:foo).with(1..2).arguments
  end

  it "passes if :sym expects 3 or more args" do
    obj = Object.new
    def obj.foo(a, b, c, *arg); end
    expect(obj).not_to respond_to(:foo).with(1..2).arguments
  end

  it "passes when target is new and initialize does not match the argument signature" do
    klass = Class.new { def initialize(a); end }
    expect(klass).to_not respond_to(:new).with(1..2).argument
  end
end

RSpec.describe "expect(...).not_to respond_to(:sym).with_unlimited_arguments" do
  it "fails if target responds to :sym with any number args" do
    obj = Object.new
    def obj.foo(*args); end
    expect {
      expect(obj).not_to respond_to(:foo).with_unlimited_arguments
    }.to fail_with(/expected .* not to respond to :foo with unlimited arguments/)
  end

  it "will fail when target is new and initialize has unlimited arguments" do
    klass = Class.new { def initialize(*args); end }
    expect {
      expect(klass).to_not respond_to(:new).with_unlimited_arguments
    }.to fail_with(/not to respond to :new with unlimited argument/)
  end

  it "passes if target does not respond to :sym" do
    obj = Object.new
    expect(obj).not_to respond_to(:some_method).with_unlimited_arguments
  end

  it "passes if :sym expects a limited number of arguments" do
    obj = Object.new
    def obj.some_method(arg); end
    expect(obj).not_to respond_to(:some_method).with_unlimited_arguments
  end

  it "passes if :sym expects a minimum number of arguments" do
    obj = Object.new
    def obj.some_method(arg, arg2, arg3, *args); end
    expect(obj).not_to respond_to(:some_method).with_unlimited_arguments
  end

  it "passes when target is new and initialize has arguments" do
    klass = Class.new { def initialize(a, *args); end }
    expect(klass).to_not respond_to(:new).with_unlimited_arguments
  end
end

if RSpec::Support::RubyFeatures.kw_args_supported?
  RSpec.describe "expect(...).to respond_to(:sym).with_keywords(:foo, :bar)" do
    it 'passes if target responds to :sym with specified optional keywords' do
      obj = Object.new
      eval %{def obj.foo(a: nil, b: nil); end}
      expect(obj).to respond_to(:foo).with_keywords(:a, :b)
    end

    it 'passes if target responds to :sym with any keywords' do
      obj = Object.new
      eval %{def obj.foo(**kw_args); end}
      expect(obj).to respond_to(:foo).with_keywords(:a, :b)
    end

    it 'passes if target is :new with keywords' do
      # note we can't use the metaobject definition for initialize
      klass = eval %{Class.new { def initialize(a: nil, b: nil); end}}
      expect(klass).to respond_to(:new).with_keywords(:a, :b)

      # note we can't use the metaobject definition for initialize
      klass_2 = eval %{Class.new { def initialize(**kw_args); end}}
      expect(klass_2).to respond_to(:new).with_keywords(:a, :b)
    end

    it "fails if target does not respond to :sym" do
      obj = Object.new
      expect {
        expect(obj).to respond_to(:some_method).with_keywords(:a, :b)
      }.to fail_with(/expected .* to respond to :some_method with keywords :a and :b/)
    end

    it "fails if :sym does not expect specified keywords" do
      obj = Object.new
      def obj.foo; end
      expect {
        expect(obj).to respond_to(:foo).with_keywords(:a, :b)
      }.to fail_with(/expected .* to respond to :foo with keywords :a and :b/)
    end

    it "fails if :sym does not expect many specified keywords" do
      obj = Object.new
      def obj.foo; end
      expect {
        expect(obj).to respond_to(:foo).with_keywords(:a, :b, :c, :d, :e, :f)
      }.to fail_with(/expected .* to respond to :foo with keywords :a, :b, :c, :d, :e, and :f/)
    end

    it 'fails if target is :new but initialize does not expect the right keywords' do
      # note we can't use the metaobject definition for initialize
      klass = eval %{Class.new { def initialize(a: nil); end}}
      expect {
        expect(klass).to respond_to(:new).with_keywords(:a, :b)
      }.to fail_with(/expected .* to respond to :new with keywords :a and :b/)
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "passes if target responds to :sym with specified required keywords" do
        obj = Object.new
        eval %{def obj.foo(a:, b:, c: nil, d: nil); end}
        expect(obj).to respond_to(:foo).with_keywords(:a, :b)
      end

      it "passes if target responds to :sym with keyword arg splat" do
        obj = Object.new
        eval %{def obj.foo(**rest); end}
        expect(obj).to respond_to(:foo).with_keywords(:a, :b)
      end

      it 'passes if target is :new and initialize has specified required keywords' do
        # note we can't use the metaobject definition for initialize
        klass = eval %{Class.new { def initialize(a:, b:); end}}
        expect(klass).to respond_to(:new).with_keywords(:a, :b)
      end

      it "fails if :sym expects specified optional keywords but expects missing required keywords" do
        obj = Object.new
        eval %{def obj.foo(a:, b:, c: nil, d: nil); end}
        expect {
          expect(obj).to respond_to(:some_method).with_keywords(:c, :d)
        }.to fail_with(/expected .* to respond to :some_method with keywords :c and :d/)
      end

      it "fails if target responds to :sym with keyword arg splat but missing required keywords" do
        obj = Object.new
        eval %{def obj.foo(a:, b:, **rest); end}
        expect {
          expect(obj).to respond_to(:some_method).with_keywords(:c, :d)
        }.to fail_with(/expected .* to respond to :some_method with keywords :c and :d/)
      end

      it 'fails if target is :new and initialize has is missing required keywords' do
        # note we can't use the metaobject definition for initialize
        klass = eval %{Class.new { def initialize(a:, b:); end}}
        expect {
          expect(klass).to respond_to(:new).with_keywords(:c, :d)
        }.to fail_with(/expected .* to respond to :new with keywords :c and :d/)
      end
    end
  end

  RSpec.describe "expect(...).to respond_to(:sym).with(2).arguments.and_keywords(:foo, :bar)" do
    it "passes if target responds to :sym with 2 args and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, b, u: nil, v: nil); end}
      expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
    end

    it "passes if target responds to :sym with any number of arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(*args, u: nil, v: nil); end}
      expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
    end

    it "passes if target responds to :sym with one or more arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, *args, u: nil, v: nil); end}
      expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
    end

    it "passes if target responds to :sym with two or more arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, b, *args, u: nil, v: nil); end}
      expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
    end

    it "fails if target does not respond to :sym" do
      obj = Object.new
      expect {
        expect(obj).to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected .* to respond to :some_method with 2 arguments and keywords :u and :v/)
    end

    it "fails if :sym expects 1 argument" do
      obj = Object.new
      eval %{def obj.foo(a, u: nil, v: nil); end}
      expect {
        expect(obj).to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected .* to respond to :some_method with 2 arguments and keywords :u and :v/)
    end

    it "fails if :sym does not expect specified keywords" do
      obj = Object.new
      def obj.foo(a, b); end
      expect {
        expect(obj).to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected .* to respond to :some_method with 2 arguments and keywords :u and :v/)
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "passes if target responds to :sym with 2 args and specified required keywords" do
        obj = Object.new
        eval %{def obj.foo(a, b, u:, v:); end}
        expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      end

      it "passes if target responds to :sym with 2 args and keyword arg splat" do
        obj = Object.new
        eval %{def obj.foo(a, b, **rest); end}
        expect(obj).to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      end

      it "passes for new when target responds to initialize with a mixture of arguments" do
        klass = eval %{Class.new { def initialize(a, b, c:, d: nil); end }}
        expect(klass).to respond_to(:new).with(2).arguments.and_keywords(:c, :d)
      end

      it "fails if :sym expects 2 arguments and specified optional keywords but expects missing required keywords" do
        obj = Object.new
        eval %{def obj.foo(a, b, u: nil, v: nil, x:, y:); end}
        expect {
          expect(obj).to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
        }.to fail_with(/expected .* to respond to :some_method with 2 arguments and keywords :u and :v/)
      end

      it "fails for new when target responds to initialize with the wrong mixture of arguments" do
        klass = eval %{Class.new { def initialize(a, b, c:); end }}
        expect {
          expect(klass).to respond_to(:new).with(2).arguments.and_keywords(:c, :d)
        }.to fail_with(/expected .* to respond to :new with 2 arguments and keywords :c and :d/)
      end
    end
  end

  RSpec.describe "expect(...).to respond_to(:sym).with_any_keywords" do
    it "passes if target responds to any keywords" do
      obj = Object.new
      eval %{def obj.foo(**kw_args); end}
      expect(obj).to respond_to(:foo).with_any_keywords
    end

    it "passes when initialize responds to any keywords and we check new" do
      klass = eval %{Class.new { def initialize(**kw_args); end }}
      expect(klass).to respond_to(:new).with_any_keywords
    end

    it "fails if target does not respond to :sym" do
      obj = Object.new
      expect {
        expect(obj).to respond_to(:some_method).with_any_keywords
      }.to fail_with(/expected .* to respond to :some_method/)
    end

    it "fails if :sym expects a limited set of keywords" do
      obj = Object.new
      eval %{def obj.some_method(a: nil, b: nil); end}
      expect {
        expect(obj).to respond_to(:some_method).with_any_keywords
      }.to fail_with(/expected .* to respond to :some_method with any keywords/)
    end

    it "fails when initialize expects a limited set of keywords and we check new" do
      klass = eval %{Class.new { def initialize(a: nil); end }}
      expect {
        expect(klass).to respond_to(:new).with_any_keywords
      }.to fail_with(/expected .* to respond to :new with any keywords/)
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "fails if :sym expects missing required keywords" do
        obj = Object.new
        eval %{def obj.some_method(a:, b:, **kw_args); end}
        expect {
          expect(obj).to respond_to(:some_method).with_any_keywords
        }.to fail_with(/expected .* to respond to :some_method with any keywords/)
      end

      it "fails if :initialize expects missing required keywords when we test new" do
        klass = eval %{Class.new { def initialize(a:, **kw_args); end }}
        eval %{def initialize(a:, b:, **kw_args); end}
        expect {
          expect(klass).to respond_to(:new).with_any_keywords
        }.to fail_with(/expected .* to respond to :new with any keywords/)
      end
    end
  end

  RSpec.describe "expect(...).not_to respond_to(:sym).with_keywords(:foo, :bar)" do
    it "fails if target responds to :sym with specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a: nil, b: nil); end}
      expect {
        expect(obj).not_to respond_to(:foo).with_keywords(:a, :b)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with keywords :a and :b/)
    end

    it "fails if target responds to :sym with any keywords" do
      obj = Object.new
      eval %{def obj.foo(**kw_args); end}
      expect {
        expect(obj).not_to respond_to(:foo).with_keywords(:a, :b)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with keywords :a and :b/)
    end

    it "fails if target initialize responds to expected keywords when checking new" do
      klass = eval %{Class.new { def initialize(**kw_args); end }}
      expect {
        expect(klass).not_to respond_to(:new).with_keywords(:a, :b)
      }.to fail_with(/expected .* not to respond to :new with keywords :a and :b/)
    end

    it "passes if target does not respond to :sym" do
      obj = Object.new
      expect(obj).not_to respond_to(:some_method).with_keywords(:a, :b)
    end

    it "passes if :sym does not expect specified keywords" do
      obj = Object.new
      eval %{def obj.foo(a: nil, b: nil); end}
      expect(obj).not_to respond_to(:some_method).with_keywords(:c, :d)
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "fails if target responds to :sym with specified required keywords" do
        obj = Object.new
        eval %{def obj.foo(a:, b:); end}
        expect {
          expect(obj).not_to respond_to(:foo).with_keywords(:a, :b)
        }.to fail_with(/expected #<Object:.*> not to respond to :foo with keywords :a and :b/)
      end

      it "fails if target responds to :sym with keyword arg splat" do
        obj = Object.new
        eval %{def obj.foo(**rest); end}
        expect {
          expect(obj).not_to respond_to(:foo).with_keywords(:a, :b)
        }.to fail_with(/expected #<Object:.*> not to respond to :foo with keywords :a and :b/)
      end

      it "passes if :sym expects missing required keywords" do
        obj = Object.new
        eval %{def obj.foo(a:, b:, c: nil, d: nil); end}
        expect(obj).not_to respond_to(:some_method).with_keywords(:c, :d)
      end

      it "passes if :initialize expects missing required keywords for :new" do
        klass = eval %{Class.new { def initialize(a:, b:, c: nil, d: nil); end }}
        expect(klass).not_to respond_to(:new).with_keywords(:c, :d)
      end
    end
  end

  RSpec.describe "expect(...).not_to respond_to(:sym).with(2).arguments.and_keywords(:foo, :bar)" do
    it "fails if target responds to :sym with 2 args and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, b, u: nil, v: nil); end}
      expect {
        expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
    end

    it "fails if target responds to :sym with any number of arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(*args, u: nil, v: nil); end}
      expect {
        expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
    end

    it "fails if target responds to :sym with one or more arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, *args, u: nil, v: nil); end}
      expect {
        expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
    end

    it "fails if target responds to :sym with two or more arguments and specified optional keywords" do
      obj = Object.new
      eval %{def obj.foo(a, b, *args, u: nil, v: nil); end}
      expect {
        expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
    end

    it "passes if target does not respond to :sym" do
      obj = Object.new
      expect(obj).not_to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
    end

    it "passes if :sym expects 1 argument" do
      obj = Object.new
      eval %{def obj.foo(a, u: nil, v: nil); end}
      expect(obj).not_to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
    end

    it "passes if :sym does not expect specified keywords" do
      obj = Object.new
      def obj.foo(a, b); end
      expect(obj).not_to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "fails if target responds to :sym with 2 args and specified required keywords" do
        obj = Object.new
        eval %{def obj.foo(a, b, u:, v:); end}
        expect {
          expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
        }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
      end

      it "fails if target responds to :sym with 2 args and keyword arg splat" do
        obj = Object.new
        eval %{def obj.foo(a, b, **rest); end}
        expect {
          expect(obj).not_to respond_to(:foo).with(2).arguments.and_keywords(:u, :v)
        }.to fail_with(/expected #<Object:.*> not to respond to :foo with 2 arguments and keywords :u and :v/)
      end

      it "passes if :sym expects 2 arguments and specified optional keywords but expects missing required keywords" do
        obj = Object.new
        eval %{def obj.foo(a, b, u: nil, v: nil, x:, y:); end}
        expect(obj).not_to respond_to(:some_method).with(2).arguments.and_keywords(:u, :v)
      end
    end
  end

  RSpec.describe "expect(...).not_to respond_to(:sym).with_any_keywords" do
    it "fails if target responds to any keywords" do
      obj = Object.new
      eval %{def obj.foo(**kw_args); end}
      expect {
        expect(obj).not_to respond_to(:foo).with_any_keywords
      }.to fail_with(/expected #<Object:.*> not to respond to :foo with any keywords/)
    end

    it "passes if target does not respond to :sym" do
      obj = Object.new
      expect(obj).not_to respond_to(:some_method).with_any_keywords
    end

    it "passes if :sym expects a limited set of keywords" do
      obj = Object.new
      eval %{def obj.some_method(a: nil, b: nil); end}
      expect(obj).not_to respond_to(:some_method).with_any_keywords
    end

    if RSpec::Support::RubyFeatures.required_kw_args_supported?
      it "passes if :sym expects missing required keywords" do
        obj = Object.new
        eval %{def obj.some_method(a:, b:, **kw_args); end}
        expect(obj).not_to respond_to(:some_method).with_any_keywords
      end
    end
  end
end
