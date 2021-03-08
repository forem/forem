RSpec.describe RSpec::Rails::MinitestLifecycleAdapter do
  it "invokes minitest lifecycle hooks at the appropriate times" do
    invocations = []
    example_group = RSpec::Core::ExampleGroup.describe("MinitestHooks") do
      include RSpec::Rails::MinitestLifecycleAdapter

      define_method(:before_setup)    { invocations << :before_setup }
      define_method(:after_setup)     { invocations << :after_setup }
      define_method(:before_teardown) { invocations << :before_teardown }
      define_method(:after_teardown)  { invocations << :after_teardown }
    end

    example_group.example("foo") { invocations << :example }
    example_group.run(NullObject.new)

    expect(invocations).to eq([
      :before_setup, :after_setup, :example, :before_teardown, :after_teardown
    ])
  end

  it "allows let variables named 'send'" do
    run_result = ::RSpec::Core::ExampleGroup.describe do
      let(:send) { "WHAT" }
      specify { expect(send).to eq "WHAT" }
    end.run NullObject.new

    expect(run_result).to be true
  end
end
