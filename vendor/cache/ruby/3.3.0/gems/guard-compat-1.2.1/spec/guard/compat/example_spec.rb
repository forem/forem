# This is the only file the plugin should require
require 'guard/compat/test/helper'
require 'guard/compat/example'

RSpec.describe Guard::MyPlugin, exclude_stubs: [Guard::Plugin] do
  let(:options) { { foo: :bar } }
  subject { described_class.new(options) }

  before do
    meths = %w(info warning error deprecation debug notify color color_enabled?)
    meths.each do |type|
      allow(Guard::Compat::UI).to receive(type.to_sym)
    end
  end

  it 'passes options' do
    expect(subject.options).to include(foo: :bar)
  end

  it 'works without options' do
    expect { described_class.new }.to_not raise_error
  end

  describe '#start' do
    before { subject.start }
    %w(info warning error deprecation debug notify).each do |type|
      specify do
        expect(Guard::Compat::UI).to have_received(type.to_sym).with('foo')
      end
    end
  end

  describe '#run_all' do
    before { subject.run_all }
    %w(info warning error deprecation debug notify).each do |type|
      specify do
        expect(Guard::Compat::UI).to have_received(type.to_sym)
          .with('foo', bar: :baz)
      end
    end
  end

  describe '#run_on_modifications' do
    before do
      allow(Guard::Compat).to receive(:matching_files)
      allow(Guard::Compat).to receive(:watched_directories)
    end

    before { subject.run_on_modifications }
    specify { expect(Guard::Compat::UI).to have_received(:color_enabled?) }
    specify { expect(Guard::Compat).to have_received(:matching_files) }
  end
end
