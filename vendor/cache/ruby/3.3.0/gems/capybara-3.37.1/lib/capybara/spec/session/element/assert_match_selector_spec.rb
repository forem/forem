# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_matches_selector' do
  before do
    @session.visit('/with_html')
    @element = @session.find(:css, 'span', text: '42')
  end

  it 'should be true if the given selector matches the element' do
    expect(@element.assert_matches_selector(:css, '.number')).to be true
  end

  it 'should be false if the given selector does not match the element' do
    expect { @element.assert_matches_selector(:css, '.not_number') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should not be callable on the session' do
    expect { @session.assert_matches_selector(:css, '.number') }.to raise_error(NoMethodError)
  end

  it 'should wait for match to occur', requires: [:js] do
    @session.visit('/with_js')
    input = @session.find(:css, '#disable-on-click')

    expect(input.assert_matches_selector(:css, 'input:enabled')).to be true
    input.click
    expect(input.assert_matches_selector(:css, 'input:disabled')).to be true
  end

  it 'should not accept count options' do
    expect { @element.assert_matches_selector(:css, '.number', count: 1) }.to raise_error(ArgumentError, /count/)
  end

  it 'should accept a filter block' do
    @element.assert_matches_selector(:css, 'span') { |el| el[:class] == 'number' }
    @element.assert_not_matches_selector(:css, 'span') { |el| el[:class] == 'not_number' }
  end
end
