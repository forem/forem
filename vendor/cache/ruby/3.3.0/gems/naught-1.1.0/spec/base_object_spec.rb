require 'spec_helper'

describe 'null object with a custom base class' do
  subject(:null) { custom_base_null_class.new }

  let(:custom_base_null_class) do
    Naught.build do |b|
      b.base_class = Object
    end
  end

  it 'responds to base class methods' do
    expect(null.methods).to be_an Array
  end

  it 'responds to unknown methods' do
    expect(null.foo).to be_nil
  end

  it 'exposes the default base class choice, for the curious' do
    default_base_class = :not_set
    Naught.build do |b|
      default_base_class = b.base_class
    end
    expect(default_base_class).to eq(Naught::BasicObject)
  end

  describe 'singleton null object' do
    subject(:null_instance) { custom_base_singleton_null_class.instance }

    let(:custom_base_singleton_null_class) do
      Naught.build do |b|
        b.singleton
        b.base_class = Object
      end
    end

    it 'can be cloned' do
      expect(null_instance.clone).to be(null_instance)
    end

    it 'can be duplicated' do
      expect(null_instance.dup).to be(null_instance)
    end
  end
end
