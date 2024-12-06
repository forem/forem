require 'spec_helper'

describe Memoizable::Memory do
  let(:memory) { Memoizable::Memory.new }

  context "serialization" do
    let(:deserialized) { Marshal.load(Marshal.dump(memory)) }

    it 'is serializable with Marshal' do
      expect { Marshal.dump(memory) }.not_to raise_error
    end

    it 'is deserializable with Marshal' do
      expect(deserialized).to be_an_instance_of(Memoizable::Memory)
    end

    it 'mantains the same class of cache when deserialized' do
      original_cache     = memory.instance_variable_get(:@memory)
      deserialized_cache = deserialized.instance_variable_get(:@memory)

      expect(deserialized_cache.class).to eql(original_cache.class)
    end
  end
end
