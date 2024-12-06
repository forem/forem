# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_css?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given selector is on the page' do
    expect(@session).to have_css('p')
    expect(@session).to have_css('p a#foo')
  end

  it 'should warn when passed a symbol' do
    # This was never a specifically accepted format but it has worked for a
    # lot of versions.
    # TODO: Remove in 4.0
    allow(Capybara::Helpers).to receive(:warn).and_return(nil)
    expect(@session).to have_css(:p)
    expect(Capybara::Helpers).to have_received(:warn)
  end

  it 'should be false if the given selector is not on the page' do
    expect(@session).not_to have_css('abbr')
    expect(@session).not_to have_css('p a#doesnotexist')
    expect(@session).not_to have_css('p.nosuchclass')
  end

  it 'should support :id option' do
    expect(@session).to have_css('h2', id: 'h2one')
    expect(@session).to have_css('h2')
    expect(@session).to have_css('h2', id: /h2o/)
    expect(@session).to have_css('li', id: /john|paul/)
  end

  it 'should support :class option' do
    expect(@session).to have_css('li', class: 'guitarist')
    expect(@session).to have_css('li', class: /guitar/)
    expect(@session).to have_css('li', class: /guitar|drummer/)
    expect(@session).to have_css('li', class: %w[beatle guitarist])
    expect(@session).to have_css('li', class: /.*/)
  end

  context ':style option' do
    it 'should support String' do
      expect(@session).to have_css('p', style: 'line-height: 25px;')

      expect do
        expect(@session).to have_css('p', style: 'display: not_valid')
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /style attribute "display: not_valid"/)
    end

    it 'should support Regexp' do
      expect(@session).to have_css('p', style: /-height: 2/)

      expect do
        expect(@session).to have_css('p', style: /not_valid/)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, %r{style attribute matching /not_valid/})
    end

    it 'should support Hash', requires: [:css] do
      expect(@session).to have_css('p', style: { 'line-height': '25px' })

      expect do
        expect(@session).to have_css('p', style: { 'line-height': '30px' })
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /with styles \{:"line-height"=>"30px"\}/)
    end
  end

  it 'should support case insensitive :class and :id options' do
    expect(@session).to have_css('li', class: /UiTaRI/i)
    expect(@session).to have_css('h2', id: /2ON/i)
  end

  context 'when scoped' do
    it 'should look in the scope' do
      @session.within "//p[@id='first']" do
        expect(@session).to have_css('a#foo')
        expect(@session).not_to have_css('a#red')
      end
    end

    it 'should be able to generate an error message if the scope is a sibling' do
      el = @session.find(:css, '#first')
      @session.within el.sibling(:css, '#second') do
        expect do
          expect(@session).to have_css('a#not_on_page')
        end.to raise_error(/there were no matches/)
      end
    end

    it 'should be able to generate an error message if the scope is a sibling from XPath' do
      el = @session.find(:css, '#first').find(:xpath, './following-sibling::*[1]') do
        expect do
          expect(el).to have_css('a#not_on_page')
        end.to raise_error(/there were no matches/)
      end
    end
  end

  it 'should wait for content to appear', requires: [:js] do
    Capybara.default_max_wait_time = 2
    @session.visit('/with_js')
    @session.click_link('Click me')
    expect(@session).to have_css("input[type='submit'][value='New Here']")
  end

  context 'with predicates_wait == true' do
    it 'should wait for content to appear', requires: [:js] do
      Capybara.predicates_wait = true
      Capybara.default_max_wait_time = 2
      @session.visit('/with_js')
      @session.click_link('Click me')
      expect(@session.has_css?("input[type='submit'][value='New Here']")).to be true
    end
  end

  context 'with predicates_wait == false' do
    before do
      Capybara.predicates_wait = false
      Capybara.default_max_wait_time = 5
      @session.visit('/with_js')
      @session.click_link('Click me')
    end

    it 'should not wait for content to appear', requires: [:js] do
      expect(@session.has_css?("input[type='submit'][value='New Here']")).to be false
    end

    it 'should should the default wait time if true is passed for :wait', requires: [:js] do
      expect(@session.has_css?("input[type='submit'][value='New Here']", wait: true)).to be true
    end
  end

  context 'with between' do
    it 'should be true if the content occurs within the range given' do
      expect(@session).to have_css('p', between: 1..4)
      expect(@session).to have_css('p a#foo', between: 1..3)
      expect(@session).to have_css('p a.doesnotexist', between: 0..8)
    end

    it 'should be false if the content occurs more or fewer times than range' do
      expect(@session).not_to have_css('p', between: 6..11)
      expect(@session).not_to have_css('p a#foo', between: 4..7)
      expect(@session).not_to have_css('p a.doesnotexist', between: 3..8)
    end
  end

  context 'with count' do
    it 'should be true if the content occurs the given number of times' do
      expect(@session).to have_css('p', count: 3)
      expect(@session).to have_css('p').exactly(3).times
      expect(@session).to have_css('p a#foo', count: 1)
      expect(@session).to have_css('p a#foo').once
      expect(@session).to have_css('p a.doesnotexist', count: 0)
      expect(@session).to have_css('li', class: /guitar|drummer/, count: 4)
      expect(@session).to have_css('li', id: /john|paul/, class: /guitar|drummer/, count: 2)
      expect(@session).to have_css('li', class: %w[beatle guitarist], count: 2)
      expect(@session).to have_css('p', style: 'line-height: 25px;', count: 1)
      expect(@session).to have_css('p', style: /-height: 2/, count: 1)
    end

    it 'should be true if the content occurs the given number of times in CSS processing drivers', requires: [:css] do
      expect(@session).to have_css('p', style: { 'line-height': '25px' }, count: 1)
    end

    it 'should be false if the content occurs a different number of times than the given' do
      expect(@session).not_to have_css('p', count: 6)
      expect(@session).not_to have_css('p').exactly(5).times
      expect(@session).not_to have_css('p a#foo', count: 2)
      expect(@session).not_to have_css('p a.doesnotexist', count: 1)
    end

    it 'should coerce count to an integer' do
      expect(@session).to have_css('p', count: '3')
      expect(@session).to have_css('p a#foo', count: '1')
    end
  end

  context 'with maximum' do
    it 'should be true when content occurs same or fewer times than given' do
      expect(@session).to have_css('h2.head', maximum: 5) # edge case
      expect(@session).to have_css('h2', maximum: 10)
      expect(@session).to have_css('h2').at_most(10).times
      expect(@session).to have_css('p a.doesnotexist', maximum: 1)
      expect(@session).to have_css('p a.doesnotexist', maximum: 0)
    end

    it 'should be false when content occurs more times than given' do
      # expect(@session).not_to have_css('h2.head', maximum: 4) # edge case
      # expect(@session).not_to have_css('h2', maximum: 3)
      expect(@session).not_to have_css('h2').at_most(3).times
      # expect(@session).not_to have_css('p', maximum: 1)
    end

    it 'should coerce maximum to an integer' do
      expect(@session).to have_css('h2.head', maximum: '5') # edge case
      expect(@session).to have_css('h2', maximum: '10')
    end
  end

  context 'with minimum' do
    it 'should be true when content occurs same or more times than given' do
      expect(@session).to have_css('h2.head', minimum: 5) # edge case
      expect(@session).to have_css('h2', minimum: 3)
      expect(@session).to have_css('h2').at_least(2).times
      expect(@session).to have_css('p a.doesnotexist', minimum: 0)
    end

    it 'should be false when content occurs fewer times than given' do
      expect(@session).not_to have_css('h2.head', minimum: 6) # edge case
      expect(@session).not_to have_css('h2', minimum: 8)
      expect(@session).not_to have_css('h2').at_least(8).times
      expect(@session).not_to have_css('p', minimum: 10)
      expect(@session).not_to have_css('p a.doesnotexist', minimum: 1)
    end

    it 'should coerce minimum to an integer' do
      expect(@session).to have_css('h2.head', minimum: '5') # edge case
      expect(@session).to have_css('h2', minimum: '3')
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      expect(@session).to have_css('p a', text: 'Redirect', count: 1)
      expect(@session).not_to have_css('p a', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is not matched' do
      expect(@session).to have_css('p a', text: /re[dab]i/i, count: 1)
      expect(@session).not_to have_css('p a', text: /Red$/)
    end
  end

  context 'with spatial requirements', requires: [:spatial] do
    before do
      @session.visit('/spatial')
    end

    let :center do
      @session.find(:css, '.center')
    end

    it 'accepts spatial options' do
      expect(@session).to have_css('div', above: center).thrice
      expect(@session).to have_css('div', above: center, right_of: center).once
    end

    it 'supports spatial sugar' do
      expect(@session).to have_css('div').left_of(center).thrice
      expect(@session).to have_css('div').below(center).right_of(center).once
      expect(@session).to have_css('div').near(center).exactly(8).times
    end
  end

  it 'should allow escapes in the CSS selector' do
    expect(@session).to have_css('p[data-random="abc\\\\def"]')
    expect(@session).to have_css("p[data-random='#{Capybara::Selector::CSS.escape('abc\def')}']")
  end
end

Capybara::SpecHelper.spec '#has_no_css?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given selector is on the page' do
    expect(@session).not_to have_no_css('p')
    expect(@session).not_to have_no_css('p a#foo')
  end

  it 'should be true if the given selector is not on the page' do
    expect(@session).to have_no_css('abbr')
    expect(@session).to have_no_css('p a#doesnotexist')
    expect(@session).to have_no_css('p.nosuchclass')
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect(@session).not_to have_no_css('a#foo')
      expect(@session).to have_no_css('a#red')
    end
  end

  it 'should wait for content to disappear', requires: [:js] do
    Capybara.default_max_wait_time = 2
    @session.visit('/with_js')
    @session.click_link('Click me')
    expect(@session).to have_no_css('p#change')
  end

  context 'with between' do
    it 'should be false if the content occurs within the range given' do
      expect(@session).not_to have_no_css('p', between: 1..4)
      expect(@session).not_to have_no_css('p a#foo', between: 1..3)
      expect(@session).not_to have_no_css('p a.doesnotexist', between: 0..2)
    end

    it 'should be true if the content occurs more or fewer times than range' do
      expect(@session).to have_no_css('p', between: 6..11)
      expect(@session).to have_no_css('p a#foo', between: 4..7)
      expect(@session).to have_no_css('p a.doesnotexist', between: 3..8)
    end
  end

  context 'with count' do
    it 'should be false if the content is on the page the given number of times' do
      expect(@session).not_to have_no_css('p', count: 3)
      expect(@session).not_to have_no_css('p a#foo', count: 1)
      expect(@session).not_to have_no_css('p a.doesnotexist', count: 0)
    end

    it 'should be true if the content is on the page the given number of times' do
      expect(@session).to have_no_css('p', count: 6)
      expect(@session).to have_no_css('p a#foo', count: 2)
      expect(@session).to have_no_css('p a.doesnotexist', count: 1)
    end

    it 'should coerce count to an integer' do
      expect(@session).not_to have_no_css('p', count: '3')
      expect(@session).not_to have_no_css('p a#foo', count: '1')
    end
  end

  context 'with maximum' do
    it 'should be false when content occurs same or fewer times than given' do
      expect(@session).not_to have_no_css('h2.head', maximum: 5) # edge case
      expect(@session).not_to have_no_css('h2', maximum: 10)
      expect(@session).not_to have_no_css('p a.doesnotexist', maximum: 0)
    end

    it 'should be true when content occurs more times than given' do
      expect(@session).to have_no_css('h2.head', maximum: 4) # edge case
      expect(@session).to have_no_css('h2', maximum: 3)
      expect(@session).to have_no_css('p', maximum: 1)
    end

    it 'should coerce maximum to an integer' do
      expect(@session).not_to have_no_css('h2.head', maximum: '5') # edge case
      expect(@session).not_to have_no_css('h2', maximum: '10')
    end
  end

  context 'with minimum' do
    it 'should be false when content occurs same or more times than given' do
      expect(@session).not_to have_no_css('h2.head', minimum: 5) # edge case
      expect(@session).not_to have_no_css('h2', minimum: 3)
      expect(@session).not_to have_no_css('p a.doesnotexist', minimum: 0)
    end

    it 'should be true when content occurs fewer times than given' do
      expect(@session).to have_no_css('h2.head', minimum: 6) # edge case
      expect(@session).to have_no_css('h2', minimum: 8)
      expect(@session).to have_no_css('p', minimum: 15)
      expect(@session).to have_no_css('p a.doesnotexist', minimum: 1)
    end

    it 'should coerce minimum to an integer' do
      expect(@session).not_to have_no_css('h2.head', minimum: '4') # edge case
      expect(@session).not_to have_no_css('h2', minimum: '3')
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      expect(@session).not_to have_no_css('p a', text: 'Redirect', count: 1)
      expect(@session).to have_no_css('p a', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is not matched' do
      expect(@session).not_to have_no_css('p a', text: /re[dab]i/i, count: 1)
      expect(@session).to have_no_css('p a', text: /Red$/)
    end
  end
end
