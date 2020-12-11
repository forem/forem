module RSpec
  module Mocks
    RSpec.describe "Serialization of mocked objects" do
      include_context "with monkey-patched marshal"

      class SerializableObject < Struct.new(:foo, :bar); end

      def self.with_yaml_loaded(&block)
        context 'with YAML loaded' do
          module_exec(&block)
        end
      end

      def self.without_yaml_loaded(&block)
        context 'without YAML loaded' do
          before do
            # We can't really unload yaml, but we can fake it here...
            hide_const("YAML")
            Struct.class_exec do
              alias __old_to_yaml to_yaml
              undef to_yaml
            end
          end

          module_exec(&block)

          after do
            Struct.class_exec do
              alias to_yaml __old_to_yaml
              undef __old_to_yaml
            end
          end
        end
      end

      let(:serializable_object) { RSpec::Mocks::SerializableObject.new(7, "something") }

      def set_stub
        allow(serializable_object).to receive_messages(:bazz => 5)
      end

      shared_examples 'normal YAML serialization' do
        it 'serializes to yaml the same with and without stubbing, using #to_yaml' do
          expect { set_stub }.to_not change { serializable_object.to_yaml }
        end

        it 'serializes to yaml the same with and without stubbing, using YAML.dump' do
          expect { set_stub }.to_not change { ::YAML.dump(serializable_object) }
        end
      end

      with_yaml_loaded do
        compiled_with_psych = begin
          require 'psych'
          true
        rescue LoadError
          false
        end

        if compiled_with_psych
          context 'using Syck as the YAML engine' do
            before(:each) { ::YAML::ENGINE.yamler = 'syck' }
            around(:each) { |example| with_isolated_stderr(&example) }
            it_behaves_like 'normal YAML serialization'
          end if defined?(::YAML::ENGINE)

          context 'using Psych as the YAML engine' do
            before(:each) { ::YAML::ENGINE.yamler = 'psych' } if defined?(::YAML::ENGINE)
            it_behaves_like 'normal YAML serialization'
          end
        else
          it_behaves_like 'normal YAML serialization'
        end
      end

      without_yaml_loaded do
        it 'does not add #to_yaml to the stubbed object' do
          expect(serializable_object).not_to respond_to(:to_yaml)
          set_stub
          expect(serializable_object).not_to respond_to(:to_yaml)
        end
      end

      it 'marshals the same with and without stubbing' do
        expect { set_stub }.to_not change { Marshal.dump(serializable_object) }
      end
    end
  end
end
