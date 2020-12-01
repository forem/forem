module RSpec
  module Mocks
    RSpec.describe ExampleMethods do
      it 'does not define private helper methods since it gets included into a ' \
         'namespace where users define methods and could inadvertently overwrite ' \
         'them' do
        expect(ExampleMethods.private_instance_methods).to eq([])
      end

      def test_extend_on_new_object(*to_extend, &block)
        host = Object.new
        to_extend.each { |mod| host.extend mod }
        host.instance_eval do
          dbl = double
          expect(dbl).to receive(:foo).at_least(:once).and_return(1)
          dbl.foo
          instance_exec(dbl, &block) if block
        end
      end

      it 'works properly when extended onto an object' do
        test_extend_on_new_object ExampleMethods
      end

      it 'works properly when extended onto an object that has previous extended `RSpec::Matchers`' do
        test_extend_on_new_object RSpec::Matchers, ExampleMethods do |dbl|
          expect(dbl.foo).to eq(1)
        end
      end

      it 'works properly when extended onto an object that later extends `RSpec::Matchers`' do
        test_extend_on_new_object ExampleMethods, RSpec::Matchers do |dbl|
          expect(dbl.foo).to eq(1)
        end
      end
    end
  end
end
