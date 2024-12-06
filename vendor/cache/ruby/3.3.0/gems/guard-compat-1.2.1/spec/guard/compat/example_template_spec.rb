require 'guard/compat/test/template'

require 'guard/compat/example'

RSpec.describe Guard::MyPlugin do
  describe 'template' do
    subject { Guard::Compat::Test::Template.new(described_class) }

    # Stub the template, because we are testing the helper, not the plugin
    let(:template_contents) do
      <<-EOS
      guard :myplugin do
        watch(/(foo).rb/) { |m| "spec/\#{m[1]}_spec.rb" }
        watch(/bar.rb/)
      end
      EOS
    end

    before do
      allow(IO).to receive(:read)
        .with('lib/guard/myplugin/templates/Guardfile')
        .and_return(template_contents)
    end

    it 'translates changes' do
      expect(subject.changed('foo.rb')).to eq(['spec/foo_spec.rb'])
      expect(subject.changed('bar.rb')).to eq(['bar.rb'])
    end
  end
end
