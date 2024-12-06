# frozen_string_literal: true

Capybara::SpecHelper.spec '#have_none_of_selectors' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if any of the given locators are on the page' do
    expect do
      expect(@session).to have_none_of_selectors(:xpath, '//p', '//a')
    end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
    expect do
      expect(@session).to have_none_of_selectors(:css, 'p a#foo')
    end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
  end

  it 'should be true if none of the given locators are on the page' do
    expect(@session).to have_none_of_selectors(:xpath, '//abbr', '//td')
    expect(@session).to have_none_of_selectors(:css, 'p a#doesnotexist', 'abbr')
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(@session).to have_none_of_selectors('p a#doesnotexist', 'abbr')
    expect do
      expect(@session).to have_none_of_selectors('abbr', 'p a#foo')
    end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
  end

  context 'should respect scopes' do
    it 'when used with `within`' do
      @session.within "//p[@id='first']" do
        expect do
          expect(@session).to have_none_of_selectors(".//a[@id='foo']")
        end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
        expect(@session).to have_none_of_selectors(".//a[@id='red']")
      end
    end

    it 'when called on an element' do
      el = @session.find "//p[@id='first']"
      expect do
        expect(el).to have_none_of_selectors(".//a[@id='foo']")
      end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
      expect(el).to have_none_of_selectors(".//a[@id='red']")
    end
  end

  context 'with options' do
    it 'should apply the options to all locators' do
      expect do
        expect(@session).to have_none_of_selectors('//p//a', text: 'Redirect')
      end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
      expect(@session).to have_none_of_selectors('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is matched' do
      expect do
        expect(@session).to have_none_of_selectors('//p//a', text: /re[dab]i/i, count: 1)
      end.to raise_error ::RSpec::Expectations::ExpectationNotMetError
      expect(@session).to have_none_of_selectors('//p//a', text: /Red$/)
    end
  end

  context 'with wait', requires: [:js] do
    it 'should not find elements if they appear after given wait duration' do
      @session.visit('/with_js')
      @session.click_link('Click me')
      expect(@session).to have_none_of_selectors(:css, '#new_field', 'a#has-been-clicked', wait: 0.1)
    end
  end

  it 'cannot be negated' do
    expect do
      expect(@session).not_to have_none_of_selectors(:css, 'p a#foo', 'h2#h2one', 'h2#h2two')
    end.to raise_error ArgumentError
  end
end
