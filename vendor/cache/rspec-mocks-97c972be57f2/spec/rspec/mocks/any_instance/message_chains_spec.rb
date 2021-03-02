RSpec.describe RSpec::Mocks::AnyInstance::MessageChains do
  let(:recorder) { double }
  let(:chains) { RSpec::Mocks::AnyInstance::MessageChains.new }
  let(:stub_chain) { RSpec::Mocks::AnyInstance::StubChain.new recorder }
  let(:expectation_chain) { RSpec::Mocks::AnyInstance::PositiveExpectationChain.new recorder }

  it "knows if a method does not have an expectation set on it" do
    chains.add(:method_name, stub_chain)
    expect(chains.has_expectation?(:method_name)).to be_falsey
  end

  it "knows if a method has an expectation set on it" do
    chains.add(:method_name, stub_chain)
    chains.add(:method_name, expectation_chain)
    expect(chains.has_expectation?(:method_name)).to be_truthy
  end

  it "can remove all stub chains" do
    chains.add(:method_name, stub_chain)
    chains.add(:method_name, expectation_chain)
    chains.add(:method_name, RSpec::Mocks::AnyInstance::StubChain.new(recorder))

    chains.remove_stub_chains_for!(:method_name)
    expect(chains[:method_name]).to eq([expectation_chain])
  end

  context "creating stub chains" do
    it "understands how to add a stub chain for a method" do
      chains.add(:method_name, stub_chain)
      expect(chains[:method_name]).to eq([stub_chain])
    end

    it "allows multiple stub chains for a method" do
      chains.add(:method_name, stub_chain)
      chains.add(:method_name, another_stub_chain = RSpec::Mocks::AnyInstance::StubChain.new(recorder))
      expect(chains[:method_name]).to eq([stub_chain, another_stub_chain])
    end
  end
end
