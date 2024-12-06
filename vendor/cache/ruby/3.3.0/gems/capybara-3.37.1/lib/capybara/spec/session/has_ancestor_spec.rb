# frozen_string_literal: true

Capybara::SpecHelper.spec '#have_ancestor' do
  before do
    @session.visit('/with_html')
  end

  it 'should assert an ancestor using the given locator' do
    el = @session.find(:css, '#ancestor1')
    expect(el).to have_ancestor(:css, '#ancestor2')
  end

  it 'should assert an ancestor even if not parent' do
    el = @session.find(:css, '#child')
    expect(el).to have_ancestor(:css, '#ancestor3')
  end

  it 'should not raise an error if there are multiple matches' do
    el = @session.find(:css, '#child')
    expect(el).to have_ancestor(:css, 'div')
  end

  it 'should allow counts to be specified' do
    el = @session.find(:css, '#child')

    expect do
      expect(el).to have_ancestor(:css, 'div').once
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError)

    expect(el).to have_ancestor(:css, 'div').exactly(3).times
  end
end

Capybara::SpecHelper.spec '#have_no_ancestor' do
  before do
    @session.visit('/with_html')
  end

  it 'should assert no matching ancestor' do
    el = @session.find(:css, '#ancestor1')
    expect(el).to have_no_ancestor(:css, '#child')
    expect(el).to have_no_ancestor(:css, '#ancestor1_sibiling')
    expect(el).not_to have_ancestor(:css, '#child')
    expect(el).not_to have_ancestor(:css, '#ancestor1_sibiling')
  end
end
