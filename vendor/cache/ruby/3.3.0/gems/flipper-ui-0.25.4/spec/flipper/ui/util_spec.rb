require 'flipper/ui/util'

RSpec.describe Flipper::UI::Util do
  describe '#blank?' do
    context 'with a string' do
      it 'returns true if blank' do
        expect(described_class.blank?(nil)).to be(true)
        expect(described_class.blank?('')).to be(true)
        expect(described_class.blank?('   ')).to be(true)
      end

      it 'returns false if not blank' do
        expect(described_class.blank?('nope')).to be(false)
      end
    end
  end
end
