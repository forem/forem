require 'spec_helper'

module Ransack
  describe Configuration do
    it 'yields Ransack on configure' do
      Ransack.configure { |config| expect(config).to eq Ransack }
    end

    it 'adds predicates' do
      Ransack.configure do |config|
        config.add_predicate :test_predicate
      end

      expect(Ransack.predicates).to have_key 'test_predicate'
      expect(Ransack.predicates).to have_key 'test_predicate_any'
      expect(Ransack.predicates).to have_key 'test_predicate_all'
    end

    it 'avoids creating compound predicates if compounds: false' do
      Ransack.configure do |config|
        config.add_predicate(
          :test_predicate_without_compound,
          :compounds => false
          )
      end
      expect(Ransack.predicates)
      .to have_key 'test_predicate_without_compound'
      expect(Ransack.predicates)
      .not_to have_key 'test_predicate_without_compound_any'
      expect(Ransack.predicates)
      .not_to have_key 'test_predicate_without_compound_all'
    end

    it 'should have default value for search key' do
      expect(Ransack.options[:search_key]).to eq :q
    end

    it 'changes default search key parameter' do
      default = Ransack.options.clone

      Ransack.configure { |c| c.search_key = :query }

      expect(Ransack.options[:search_key]).to eq :query

      Ransack.options = default
    end

    it 'should have default values for arrows' do
      expect(Ransack.options[:up_arrow]).to eq '&#9660;'
      expect(Ransack.options[:down_arrow]).to eq '&#9650;'
      expect(Ransack.options[:default_arrow]).to eq nil
    end

    it 'changes the default value for the up arrow only' do
      default, new_up_arrow = Ransack.options.clone, 'U+02191'

      Ransack.configure { |c| c.custom_arrows = { up_arrow: new_up_arrow } }

      expect(Ransack.options[:down_arrow]).to eq default[:down_arrow]
      expect(Ransack.options[:up_arrow]).to eq new_up_arrow

      Ransack.options = default
    end

    it 'changes the default value for the down arrow only' do
      default, new_down_arrow  = Ransack.options.clone, '<i class="down"></i>'

      Ransack.configure { |c| c.custom_arrows = { down_arrow: new_down_arrow } }

      expect(Ransack.options[:up_arrow]).to eq default[:up_arrow]
      expect(Ransack.options[:down_arrow]).to eq new_down_arrow

      Ransack.options = default
    end

    it 'changes the default value for the default arrow only' do
      default, new_default_arrow  = Ransack.options.clone, '<i class="default"></i>'

      Ransack.configure { |c| c.custom_arrows = { default_arrow: new_default_arrow } }

      expect(Ransack.options[:up_arrow]).to eq default[:up_arrow]
      expect(Ransack.options[:down_arrow]).to eq default[:down_arrow]
      expect(Ransack.options[:default_arrow]).to eq new_default_arrow

      Ransack.options = default
    end

    it 'changes the default value for all arrows' do
      default        = Ransack.options.clone
      new_up_arrow   = '<i class="fa fa-long-arrow-up"></i>'
      new_down_arrow = 'U+02193'
      new_default_arrow = 'defaultarrow'

      Ransack.configure do |c|
        c.custom_arrows = { up_arrow: new_up_arrow, down_arrow: new_down_arrow, default_arrow: new_default_arrow }
      end

      expect(Ransack.options[:up_arrow]).to eq new_up_arrow
      expect(Ransack.options[:down_arrow]).to eq new_down_arrow
      expect(Ransack.options[:default_arrow]).to eq new_default_arrow

      Ransack.options = default
    end

    it 'consecutive arrow customizations respect previous customizations' do
      default = Ransack.options.clone

      Ransack.configure { |c| c.custom_arrows = { up_arrow: 'up' } }
      expect(Ransack.options[:down_arrow]).to eq default[:down_arrow]

      Ransack.configure { |c| c.custom_arrows = { down_arrow: 'DOWN' } }
      expect(Ransack.options[:up_arrow]).to eq 'up'

      Ransack.configure { |c| c.custom_arrows = { up_arrow: '<i>U-Arrow</i>' } }
      expect(Ransack.options[:down_arrow]).to eq 'DOWN'

      Ransack.configure { |c| c.custom_arrows = { down_arrow: 'down arrow-2' } }
      expect(Ransack.options[:up_arrow]).to eq '<i>U-Arrow</i>'

      Ransack.options = default
    end

    it 'adds predicates that take arrays, overriding compounds' do
      Ransack.configure do |config|
        config.add_predicate(
          :test_array_predicate,
          :wants_array => true,
          :compounds => true
          )
      end

      expect(Ransack.predicates['test_array_predicate'].wants_array).to eq true
      expect(Ransack.predicates).not_to have_key 'test_array_predicate_any'
      expect(Ransack.predicates).not_to have_key 'test_array_predicate_all'
    end

    describe '`wants_array` option takes precedence over Arel predicate' do
      it 'implicitly wants an array for in/not in predicates' do
        Ransack.configure do |config|
          config.add_predicate(
            :test_in_predicate,
            :arel_predicate => 'in'
          )
          config.add_predicate(
            :test_not_in_predicate,
            :arel_predicate => 'not_in'
          )
        end

        expect(Ransack.predicates['test_in_predicate'].wants_array)
        .to eq true
        expect(Ransack.predicates['test_not_in_predicate'].wants_array)
        .to eq true
      end

      it 'explicitly does not want array for in/not_in predicates' do
        Ransack.configure do |config|
          config.add_predicate(
            :test_in_predicate_no_array,
            :arel_predicate => 'in',
            :wants_array => false
          )
          config.add_predicate(
            :test_not_in_predicate_no_array,
            :arel_predicate => 'not_in',
            :wants_array => false
          )
        end

        expect(Ransack.predicates['test_in_predicate_no_array'].wants_array)
        .to eq false
        expect(Ransack.predicates['test_not_in_predicate_no_array'].wants_array)
        .to eq false
      end
    end
  end
end
