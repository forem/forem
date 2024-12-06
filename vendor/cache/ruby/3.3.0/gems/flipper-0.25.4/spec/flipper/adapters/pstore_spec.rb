require 'flipper/adapters/pstore'

RSpec.describe Flipper::Adapters::PStore do
  subject do
    dir = FlipperRoot.join('tmp').tap(&:mkpath)
    pstore_file = dir.join('flipper.pstore')
    pstore_file.unlink if pstore_file.exist?
    described_class.new(pstore_file)
  end

  it_should_behave_like 'a flipper adapter'

  it 'defaults path to flipper.pstore' do
    expect(described_class.new.path).to eq('flipper.pstore')
  end
end
