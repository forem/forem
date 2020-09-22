RSpec.describe SnakyHash do
  subject { described_class.new }

  describe '.build' do
    context 'build from hash' do
      subject { described_class.build({ 'AccessToken' => '1' }) }

      it 'create correct snake hash' do
        expect(subject).to be_a(described_class)
        expect(subject['AccessToken']).to eq('1')
        expect(subject['access_token']).to eq('1')
      end
    end

    context 'build from snake_hash' do
      subject do
        h = described_class.new
        h['AccessToken'] = '1'

        described_class.build(h)
      end

      it 'create correct snake hash' do
        expect(subject).to be_a(described_class)
        expect(subject['AccessToken']).to eq('1')
        expect(subject['access_token']).to eq('1')
      end
    end
  end

  describe 'assign and query' do
    it 'returns assigned value with camel key' do
      subject['AccessToken'] = '1'

      expect(subject['AccessToken']).to eq('1')
      expect(subject['access_token']).to eq('1')
    end

    it 'returns assigned value with snake key only' do
      subject['access_token'] = '1'

      expect(subject['AccessToken']).to eq(nil)
      expect(subject['access_token']).to eq('1')
    end

    it 'overwrite snake key' do
      subject['AccessToken'] = '1'

      expect(subject['AccessToken']).to eq('1')
      expect(subject['access_token']).to eq('1')

      subject['access_token'] = '2'

      expect(subject['AccessToken']).to eq('1')
      expect(subject['access_token']).to eq('2')
    end
  end

  describe '#fetch' do
    context 'Camel case key' do
      subject { described_class.build('AccessToken' => '1') }

      it 'return correct token' do
        expect(subject.fetch('access_token')).to eq('1')
      end
    end

    context 'Camel case key with dowcased first letter' do
      subject { described_class.build('accessToken' => '1') }

      it 'return correct token' do
        expect(subject.fetch('access_token')).to eq('1')
      end
    end

    context 'snake case key' do
      subject { described_class.build('access_token' => '1') }

      it 'return correct token' do
        expect(subject.fetch('access_token')).to eq('1')
      end
    end

    context 'missing any key' do
      subject { described_class.new }

      it 'raise KeyError with key' do
        expect {
          subject.fetch('access_token')
        }.to raise_error(KeyError, /access_token/)
      end

      it 'return default value' do
        expect(subject.fetch('access_token') {'default'}).to eq('default')
      end
    end
  end

  describe '#key?' do
   context 'Camel case key' do
      subject { described_class.build('AccessToken' => '1') }

      it 'return true' do
        expect(subject.key?('access_token')).to eq(true)
      end
    end

    context 'Camel case key with dowcased first letter' do
      subject { described_class.build('accessToken' => '1') }

      it 'return true' do
        expect(subject.key?('access_token')).to eq(true)
      end
    end

    context 'snake case key' do
      subject { described_class.build('access_token' => '1') }

      it 'return true' do
        expect(subject.key?('access_token')).to eq(true)
      end
    end

    context 'missing any key' do
      subject { described_class.new }

      it 'return false' do
        expect(subject.key?('access_token')).to eq(false)
      end
    end
  end
end
