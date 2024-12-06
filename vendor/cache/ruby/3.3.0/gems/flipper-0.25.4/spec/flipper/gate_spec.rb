RSpec.describe Flipper::Gate do
  let(:feature_name) { :stats }

  subject do
    described_class.new
  end

  describe '#inspect' do
    context 'for subclass' do
      let(:subclass) do
        Class.new(described_class) do
          def name
            :name
          end

          def key
            :key
          end

          def data_type
            :set
          end
        end
      end

      subject do
        subclass.new
      end

      it 'includes attributes' do
        string = subject.inspect
        expect(string).to include(subject.object_id.to_s)
        expect(string).to include('name=:name')
        expect(string).to include('key=:key')
        expect(string).to include('data_type=:set')
      end
    end
  end
end
