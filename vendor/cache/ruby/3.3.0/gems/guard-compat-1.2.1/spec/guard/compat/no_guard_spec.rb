# This test requires UI be not defined to simulate using plugin outside Guard

require 'guard/compat/plugin'

Guard.send(:remove_const, :UI) if Guard.const_defined?(:UI)

RSpec.describe Guard::Compat do
  context 'when Guard is not loaded' do
    describe '.color' do
      it 'returns uncolored text' do
        expect(Guard::Compat::UI.color('foo', 'red')).to eq('foo')
      end
    end

    describe '.color_enabled?' do
      it 'returns false' do
        expect(Guard::Compat::UI.color_enabled?).to be(false)
      end
    end

    describe '.info' do
      it 'outputs to stdout' do
        expect($stdout).to receive(:puts).with('foo')
        Guard::Compat::UI.info('foo')
      end
    end

    describe '.warning' do
      it 'outputs to stdout' do
        expect($stdout).to receive(:puts).with('foo')
        Guard::Compat::UI.warning('foo')
      end
    end

    describe '.error' do
      it 'outputs to stdout' do
        expect($stderr).to receive(:puts).with('foo')
        Guard::Compat::UI.error('foo')
      end
    end

    describe '.debug' do
      it 'outputs to stdout' do
        expect($stdout).to receive(:puts).with('foo')
        Guard::Compat::UI.debug('foo')
      end
    end

    describe '.deprecation' do
      it 'outputs to stdout' do
        expect($stdout).to receive(:puts).with('foo')
        Guard::Compat::UI.deprecation('foo')
      end
    end

    describe '.notify' do
      it 'outputs to stdout' do
        expect($stdout).to receive(:puts).with('foo')
        Guard::Compat::UI.notify('foo')
      end
    end
  end
end
