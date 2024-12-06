# frozen_string_literal: true

Capybara::SpecHelper.spec '#have_any_of_selectors' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if any of the given selectors are on the page' do
    expect(@session).to have_any_of_selectors(:css, 'p a#foo', 'h2#blah', 'h2#h2two')
  end

  it 'should be false if none of the given selectors are not on the page' do
    expect do
      expect(@session).to have_any_of_selectors(:css, 'span a#foo', 'h2#h2nope', 'h2#h2one_no')
    end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(@session).to have_any_of_selectors('p a#foo', 'h2#h2two', 'a#not_on_page')
    expect do
      expect(@session).to have_any_of_selectors('p a#blah', 'h2#h2three')
    end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
  end

  it 'should be negateable' do
    expect(@session).not_to have_any_of_selectors(:css, 'span a#foo', 'h2#h2nope', 'h2#h2one_no')
  end
end
