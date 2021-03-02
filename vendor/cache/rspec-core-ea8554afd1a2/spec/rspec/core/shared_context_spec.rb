RSpec.describe RSpec::SharedContext do
  it "is accessible as RSpec::Core::SharedContext" do
    RSpec::Core::SharedContext
  end

  it "is accessible as RSpec::SharedContext" do
    RSpec::SharedContext
  end

  it "supports before and after hooks" do
    before_all_hook = false
    before_each_hook = false
    after_each_hook = false
    after_all_hook = false
    shared = Module.new do
      extend RSpec::SharedContext
      before(:all) { before_all_hook = true }
      before(:each) { before_each_hook = true }
      after(:each)  { after_each_hook = true }
      after(:all)  { after_all_hook = true }
    end
    group = RSpec.describe do
      include shared
      example { }
    end

    group.run

    expect(before_all_hook).to be(true)
    expect(before_each_hook).to be(true)
    expect(after_each_hook).to be(true)
    expect(after_all_hook).to be(true)
  end

  include RSpec::Core::SharedExampleGroup::TopLevelDSL

  it "runs the before each hooks in configuration before those of the shared context" do
    ordered_hooks = []
    RSpec.configure do |c|
      c.before(:each) { ordered_hooks << "config" }
    end

    RSpec.shared_context("before each stuff", :example => :before_each_hook_order) do
      before(:each) { ordered_hooks << "shared_context"}
    end

    group = RSpec.describe "description", :example => :before_each_hook_order do
      before(:each) { ordered_hooks << "example_group" }
      example {}
    end

    group.run

    expect(ordered_hooks).to be == ["config", "shared_context", "example_group"]
  end

  it "supports let" do
    shared = Module.new do
      extend RSpec::SharedContext
      let(:foo) { 'foo' }
    end
    group = RSpec.describe do
      include shared
    end

    expect(group.new.foo).to eq('foo')
  end

  it 'supports overriding let without warnings' do
    shared = Module.new do
      extend RSpec::SharedContext
      let(:foo) { 'foo' }
    end
    group = RSpec.describe do
      include shared
      let(:foo) { 'bar' }
    end

    expect(group.new.foo).to eq('bar')
  end

  it "supports let when applied to an individual example via metadata" do
    shared = Module.new do
      extend RSpec::SharedContext
      let(:foo) { "bar" }
    end

    RSpec.configuration.include shared, :include_it

    ex = value = nil
    RSpec.describe "group" do
      ex = example("ex1", :include_it) { value = foo }
    end.run

    expect(ex.execution_result).to have_attributes(:status => :passed, :exception => nil)
    expect(value).to eq("bar")
  end

  it 'supports explicit subjects' do
    shared = Module.new do
      extend RSpec::SharedContext
      subject { 17 }
    end

    group = RSpec.describe do
      include shared
    end

    expect(group.new.subject).to eq(17)
  end

  %w[describe context].each do |method_name|
    it "supports nested example groups using #{method_name}" do
      shared = Module.new do
        extend RSpec::SharedContext
        send(method_name, "nested using describe") do
          example {}
        end
      end
      group = RSpec.describe do
        include shared
      end

      group.run

      expect(group.children.length).to eq(1)
      expect(group.children.first.examples.length).to eq(1)
    end
  end
end
