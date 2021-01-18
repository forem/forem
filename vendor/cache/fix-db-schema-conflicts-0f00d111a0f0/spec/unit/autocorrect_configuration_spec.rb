require 'spec_helper'
require 'fix_db_schema_conflicts/autocorrect_configuration'

RSpec.describe FixDBSchemaConflicts::AutocorrectConfiguration do
  subject(:autocorrect_config) { described_class }

  it 'for versions up to 0.49.0' do
    installed_rubocop(version: '0.39.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.yml')
  end

  it 'for versions 0.49.0 and above' do
    installed_rubocop(version: '0.49.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.49.yml')
  end

  it 'for versions 0.53.0 and above' do
    installed_rubocop(version: '0.53.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.53.yml')
  end

  def installed_rubocop(version:)
    allow(Gem).to receive_message_chain(:loaded_specs, :[], :version)
      .and_return(Gem::Version.new(version))
  end
end
