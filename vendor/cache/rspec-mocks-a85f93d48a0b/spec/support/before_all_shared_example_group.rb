RSpec.shared_examples "fails in a before(:all) block" do
  the_error = nil
  before(:all) do
    begin
      use_rspec_mocks
    rescue
      the_error = $!
    end
  end

  it "raises an error with a useful message" do
    expect(the_error).to be_a_kind_of(RSpec::Mocks::OutsideOfExampleError)

    expect(the_error.message).to match(/The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported./)
  end
end
