require 'spec_helper'

describe 'have_role', focus: true do
  let(:object) { Object.new }

  it 'delegates to has_role?' do
    object.should_receive(:has_role?).with(:read, 'Resource') { true }
    object.should have_role(:read, 'Resource')
  end

  it 'reports a nice failure message for should' do
    object.should_receive(:has_role?) { false }
    expect{
      object.should have_role(:read, 'Resource')
    }.to raise_error('expected to have role :read "Resource"')
  end

  it 'reports a nice failure message for should_not' do
    object.should_receive(:has_role?) { true }
    expect{
      object.should_not have_role(:read, 'Resource')
    }.to raise_error('expected not to have role :read "Resource"')
  end
end
