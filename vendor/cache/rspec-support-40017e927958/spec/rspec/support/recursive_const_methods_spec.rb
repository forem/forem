require 'rspec/support/recursive_const_methods'

module RSpec
  module Support
    RSpec.describe RecursiveConstMethods do
      include described_class

      module Foo
        class Parent
          UNDETECTED = 'Not seen when looking up constants in Bar'
        end

        class Bar < Parent
          VAL = 10
        end
      end

      describe '#recursive_const_defined?' do
        it 'finds constants' do
          const, _ = recursive_const_defined?('::RSpec::Support::Foo::Bar::VAL')

          expect(const).to eq(10)
        end

        it 'returns the fully qualified name of the constant' do
          _, name = recursive_const_defined?('::RSpec::Support::Foo::Bar::VAL')

          expect(name).to eq('RSpec::Support::Foo::Bar::VAL')
        end

        it 'does not find constants in ancestors' do
          expect(recursive_const_defined?('::RSpec::Support::Foo::Bar::UNDETECTED')).to be_falsy
        end

        it 'does not blow up on buggy classes that raise weird errors on `to_str`' do
          allow(Foo::Bar).to receive(:to_str).and_raise("boom!")
          const, _ = recursive_const_defined?('::RSpec::Support::Foo::Bar::VAL')

          expect(const).to eq(10)
        end
      end

      describe '#recursive_const_get' do
        it 'gets constants' do
          expect(recursive_const_get('::RSpec::Support::Foo::Bar::VAL')).to eq(10)
        end

        it 'does not get constants in ancestors' do
          expect do
            recursive_const_get('::RSpec::Support::Foo::Bar::UNDETECTED')
          end.to raise_error(NameError)
        end
      end
    end
  end
end
