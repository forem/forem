RSpec.describe RSpec::Rails::MinitestAssertionAdapter do
  include RSpec::Rails::MinitestAssertionAdapter

  RSpec::Rails::Assertions.public_instance_methods.select { |m| m.to_s =~ /^(assert|flunk|refute)/ }.each do |m|
    if m.to_s == "assert_equal"
      it "exposes #{m} to host examples" do
        assert_equal 3, 3
        expect do
          assert_equal 3, 4
        end.to raise_error(ActiveSupport::TestCase::Assertion)
      end
    else
      it "exposes #{m} to host examples" do
        expect(methods).to include(m)
      end
    end
  end

  it "does not expose internal methods of Minitest" do
    expect(methods).not_to include("_assertions")
  end

  it "does not expose Minitest's message method" do
    expect(methods).not_to include("message")
  end

  it 'does not leak TestUnit specific methods into the AssertionDelegator' do
    expect(methods).to_not include(:build_message)
  end
end
