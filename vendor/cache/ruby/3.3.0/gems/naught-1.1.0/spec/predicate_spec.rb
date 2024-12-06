require 'spec_helper'

describe 'a null object with predicates_return(false)' do
  subject(:null) { null_class.new }
  let(:null_class) do
    Naught.build do |config|
      config.predicates_return false
    end
  end

  it 'responds to predicate-style methods with false' do
    expect(null.too_much_coffee?).to be(false)
  end

  it 'responds to other methods with nil' do
    expect(null.foobar).to be(nil)
  end

  describe '(black hole)' do
    let(:null_class) do
      Naught.build do |config|
        config.black_hole
        config.predicates_return false
      end
    end

    it 'responds to predicate-style methods with false' do
      expect(null.too_much_coffee?).to be(false)
    end

    it 'responds to other methods with self' do
      expect(null.foobar).to be(null)
    end
  end

  describe '(black hole, reverse order config)' do
    let(:null_class) do
      Naught.build do |config|
        config.predicates_return false
        config.black_hole
      end
    end

    it 'responds to predicate-style methods with false' do
      expect(null.too_much_coffee?).to be(false)
    end

    it 'responds to other methods with self' do
      expect(null.foobar).to be(null)
    end
  end

  class Coffee
    attr_reader :origin
    def black?; end
  end

  describe '(mimic)' do
    let(:null_class) do
      Naught.build do |config|
        config.mimic Coffee
        config.predicates_return false
      end
    end

    it 'responds to predicate-style methods with false' do
      expect(null.black?).to be(false)
    end

    it 'responds to other methods with nil' do
      expect(null.origin).to be(nil)
    end

    it 'does not respond to undefined methods' do
      expect(null).not_to respond_to(:leaf_variety)
      expect { null.leaf_variety }.to raise_error(NoMethodError)
    end
  end
end
