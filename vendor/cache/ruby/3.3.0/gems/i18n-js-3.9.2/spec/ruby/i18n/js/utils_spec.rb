require "spec_helper"

describe I18n::JS::Utils do

  describe ".strip_keys_with_nil_values" do
    subject { described_class.strip_keys_with_nil_values(input_hash) }

    context 'when input_hash does NOT contain nil value' do
      let(:input_hash) { {a: 1, b: { c: 2 }} }
      let(:expected_hash) { input_hash }

      it 'returns the original input' do
        is_expected.to eq expected_hash
      end
    end
    context 'when input_hash does contain nil value' do
      let(:input_hash) { {a: 1, b: { c: 2, d: nil }, e: { f: nil }} }
      let(:expected_hash) { {a: 1, b: { c: 2 }, e: {}} }

      it 'returns the original input with nil values removed' do
        is_expected.to eq expected_hash
      end
    end
  end

  context "hash merging" do
    it "performs a deep merge" do
      target = {:a => {:b => 1}}
      result = described_class.deep_merge(target, {:a => {:c => 2}})

      expect(result[:a]).to eql({:b => 1, :c => 2})
    end

    it "performs a banged deep merge" do
      target = {:a => {:b => 1}}
      described_class.deep_merge!(target, {:a => {:c => 2}})

      expect(target[:a]).to eql({:b => 1, :c => 2})
    end
  end

  describe ".deep_reject" do
    it "performs a deep keys rejection" do
      hash = {:a => {:b => 1}}

      result = described_class.deep_reject(hash) { |k, v| k == :b }

      expect(result).to eql({:a => {}})
    end

    it "performs a deep keys rejection prunning the whole tree if necessary" do
      hash = {:a => {:b => {:c => {:d => 1, :e => 2}}}}

      result = described_class.deep_reject(hash) { |k, v| k == :b }

      expect(result).to eql({:a => {}})
    end


    it "performs a deep keys rejection without changing the original hash" do
      hash = {:a => {:b => 1, :c => 2}}

      result = described_class.deep_reject(hash) { |k, v| k == :b }

      expect(result).to eql({:a => {:c => 2}})
      expect(hash).to eql({:a => {:b => 1, :c => 2}})
    end
  end

  describe ".deep_key_sort" do
    let(:unsorted_hash) { {:z => {:b => 1, :a => 2}, :y => 3} }
    subject(:sorting) { described_class.deep_key_sort(unsorted_hash) }

    it "performs a deep keys sort without changing the original hash" do
      should eql({:y => 3, :z => {:a => 2, :b => 1}})
      expect(unsorted_hash).to eql({:z => {:b => 1, :a => 2}, :y => 3})
    end

    # Idea from gem `rails_admin`
    context "when hash contain non-Symbol as key" do
      let(:unsorted_hash) { {:z => {1 => 1, true => 2}, :y => 3} }

      it "performs a deep keys sort without error" do
        expect{ sorting }.to_not raise_error
      end
      it "converts keys to symbols" do
        should eql({:y => 3, :z => {1 => 1, true => 2}})
      end
    end
  end

  describe ".scopes_match?" do
    it "performs a comparison of literal scopes" do
      expect(described_class.scopes_match?([:a, :b], [:a, :b, :c])).to_not eql true
      expect(described_class.scopes_match?([:a, :b, :c], [:a, :b, :c])).to eql true
      expect(described_class.scopes_match?([:a, :b, :c], [:a, :b, :d])).to_not eql true
    end

    it "performs a comparison of wildcard scopes" do
      expect(described_class.scopes_match?([:a, '*'], [:a, :b, :c])).to_not eql true
      expect(described_class.scopes_match?([:a, '*', :c], [:a, :b, :c])).to eql true
      expect(described_class.scopes_match?([:a, :b, :c], [:a, '*', :c])).to eql true
      expect(described_class.scopes_match?([:a, :b, :c], [:a, '*', '*'])).to eql true
    end
  end

  describe ".deep_remove_procs" do
    let(:proc_obj) { proc {} }
    let(:hash_with_proc) do
      {
        :a => :b,
        :c => proc_obj,
        :d => {
          :e => proc_obj,
          :f => :g,
        }
      }
    end
    subject { described_class.deep_remove_procs(hash_with_proc) }

    it "performs a deep keys sort without changing the original hash" do
      should eql({
        :a => :b,
        :d => {
          :f => :g,
        }
      })
      expect(hash_with_proc).to eql({
        :a => :b,
        :c => proc_obj,
        :d => {
          :e => proc_obj,
          :f => :g,
        }
      })
    end
  end
end
