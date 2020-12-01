RSpec.describe Marshal, 'extensions' do
  # An object that raises when code attempts to dup it.
  #
  # Because we manipulate the internals of RSpec::Mocks.space below, we need
  # an object that simply blows up when #dup is called without using any
  # partial mocking or stubbing from rspec-mocks itself.
  class UndupableObject
    def dup
      raise NotImplementedError
    end
  end

  describe '#dump' do
    context 'when rspec-mocks has been fully initialized' do
      include_context "with monkey-patched marshal"

      it 'duplicates objects with stubbed or mocked implementations before serialization' do
        obj = double(:foo => "bar")

        serialized = Marshal.dump(obj)
        expect(Marshal.load(serialized)).to be_an(obj.class)
      end

      it 'does not duplicate other objects before serialization' do
        obj = UndupableObject.new

        serialized = Marshal.dump(obj)
        expect(Marshal.load(serialized)).to be_an(UndupableObject)
      end

      it 'does not duplicate nil before serialization' do
        serialized = Marshal.dump(nil)
        expect(Marshal.load(serialized)).to be_nil
      end

      specify 'applying and unapplying patch is idempotent' do
        obj = double(:foo => "bar")
        config = RSpec::Mocks.configuration

        config.patch_marshal_to_support_partial_doubles = true
        config.patch_marshal_to_support_partial_doubles = true
        serialized = Marshal.dump(obj)
        expect(Marshal.load(serialized)).to be_an(obj.class)
        config.patch_marshal_to_support_partial_doubles = false
        config.patch_marshal_to_support_partial_doubles = false
        expect { Marshal.dump(obj) }.to raise_error(TypeError)
      end
    end

    context 'outside the per-test lifecycle' do
      def outside_per_test_lifecycle
        RSpec::Mocks.teardown
        yield
      ensure
        RSpec::Mocks.setup
      end

      it 'does not duplicate the object before serialization' do
        obj = UndupableObject.new
        outside_per_test_lifecycle do
          serialized = Marshal.dump(obj)
          expect(Marshal.load(serialized)).to be_an(UndupableObject)
        end
      end
    end
  end
end
