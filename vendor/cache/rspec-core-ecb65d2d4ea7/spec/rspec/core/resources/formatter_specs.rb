# Deliberately named _specs.rb to avoid being loaded except when specified

RSpec.shared_examples_for "shared" do
  it "is marked as pending but passes" do
    pending
    expect(1).to eq(1)
  end
end

RSpec.describe "pending spec with no implementation" do
  it "is pending"
end

RSpec.describe "pending command with block format" do
  context "with content that would fail" do
    it "is pending" do
      pending
      expect(1).to eq(2)
    end
  end

  it_behaves_like "shared"
end

RSpec.describe "passing spec" do
  it "passes" do
    expect(1).to eq(1)
  end

  it 'passes with a multiple
     line description' do
  end
end

RSpec.describe "failing spec" do
  it "fails" do
    expect(1).to eq(2)
  end

  it "fails twice", :aggregate_failures do
    expect(1).to eq(2)
    expect(3).to eq(4)
  end
end

RSpec.describe "a failing spec with odd backtraces" do
  it "fails with a backtrace that has no file" do
    require 'erb'

    ERB.new("<%= raise 'foo' %>").result
  end

  it "fails with a backtrace containing an erb file" do
    e = Exception.new

    def e.backtrace
      ["/foo.html.erb:1:in `<main>': foo (RuntimeError)",
        "   from /lib/ruby/1.9.1/erb.rb:753:in `eval'"]
    end

    def e.message
      # Redefining message steps around this behaviour
      # on JRuby: http://jira.codehaus.org/browse/JRUBY-5637
      self.class.name
    end

    raise e
  end

  context "with a `nil` backtrace" do
    it "raises" do
      raise "boom"
    end

    after { |ex| ex.exception.set_backtrace(nil) }
  end
end
