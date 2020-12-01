RSpec.describe RSpec::Core::Pending do
  it 'only defines methods that are part of the DSL' do
    expect(RSpec::Core::Pending.instance_methods(false).map(&:to_sym)).to \
      match_array([:pending, :skip])
  end
end
