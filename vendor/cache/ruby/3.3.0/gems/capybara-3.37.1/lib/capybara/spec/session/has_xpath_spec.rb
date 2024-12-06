# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_xpath?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given selector is on the page' do
    expect(@session).to have_xpath('//p')
    expect(@session).to have_xpath("//p//a[@id='foo']")
    expect(@session).to have_xpath("//p[contains(.,'est')]")
  end

  it 'should support :id option' do
    expect(@session).to have_xpath('//h2', id: 'h2one')
    expect(@session).to have_xpath('//h2')
    expect(@session).to have_xpath('//h2', id: /h2o/)
  end

  it 'should support :class option' do
    expect(@session).to have_xpath('//li', class: 'guitarist')
    expect(@session).to have_xpath('//li', class: /guitar/)
    expect(@session).to have_xpath('//li', class: /guitar|drummer/)
    expect(@session).to have_xpath('//li', class: %w[beatle guitarist])
    expect(@session).to have_xpath('//li', class: /.*/)
  end

  it 'should be false if the given selector is not on the page' do
    expect(@session).not_to have_xpath('//abbr')
    expect(@session).not_to have_xpath("//p//a[@id='doesnotexist']")
    expect(@session).not_to have_xpath("//p[contains(.,'thisstringisnotonpage')]")
  end

  it 'should use xpath even if default selector is CSS' do
    Capybara.default_selector = :css
    expect(@session).not_to have_xpath("//p//a[@id='doesnotexist']")
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect(@session).to have_xpath(".//a[@id='foo']")
      expect(@session).not_to have_xpath(".//a[@id='red']")
    end
  end

  it 'should wait for content to appear', requires: [:js] do
    Capybara.using_wait_time(3) do
      @session.visit('/with_js')
      @session.click_link('Click me') # updates page after 500ms
      expect(@session).to have_xpath("//input[@type='submit' and @value='New Here']")
    end
  end

  context 'with count' do
    it 'should be true if the content occurs the given number of times' do
      expect(@session).to have_xpath('//p', count: 3)
      expect(@session).to have_xpath("//p//a[@id='foo']", count: 1)
      expect(@session).to have_xpath("//p[contains(.,'est')]", count: 1)
      expect(@session).to have_xpath("//p//a[@id='doesnotexist']", count: 0)
      expect(@session).to have_xpath('//li', class: /guitar|drummer/, count: 4)
      expect(@session).to have_xpath('//li', id: /john|paul/, class: /guitar|drummer/, count: 2)
      expect(@session).to have_xpath('//li', class: %w[beatle guitarist], count: 2)
    end

    it 'should be false if the content occurs a different number of times than the given' do
      expect(@session).not_to have_xpath('//p', count: 6)
      expect(@session).not_to have_xpath("//p//a[@id='foo']", count: 2)
      expect(@session).not_to have_xpath("//p[contains(.,'est')]", count: 5)
      expect(@session).not_to have_xpath("//p//a[@id='doesnotexist']", count: 1)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      expect(@session).to have_xpath('//p//a', text: 'Redirect', count: 1)
      expect(@session).not_to have_xpath('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is not matched' do
      expect(@session).to have_xpath('//p//a', text: /re[dab]i/i, count: 1)
      expect(@session).not_to have_xpath('//p//a', text: /Red$/)
    end
  end
end

Capybara::SpecHelper.spec '#has_no_xpath?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given selector is on the page' do
    expect(@session).not_to have_no_xpath('//p')
    expect(@session).not_to have_no_xpath("//p//a[@id='foo']")
    expect(@session).not_to have_no_xpath("//p[contains(.,'est')]")
  end

  it 'should be true if the given selector is not on the page' do
    expect(@session).to have_no_xpath('//abbr')
    expect(@session).to have_no_xpath("//p//a[@id='doesnotexist']")
    expect(@session).to have_no_xpath("//p[contains(.,'thisstringisnotonpage')]")
  end

  it 'should use xpath even if default selector is CSS' do
    Capybara.default_selector = :css
    expect(@session).to have_no_xpath("//p//a[@id='doesnotexist']")
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect(@session).not_to have_no_xpath(".//a[@id='foo']")
      expect(@session).to have_no_xpath(".//a[@id='red']")
    end
  end

  it 'should wait for content to disappear', requires: [:js] do
    Capybara.default_max_wait_time = 2
    @session.visit('/with_js')
    @session.click_link('Click me')
    expect(@session).to have_no_xpath("//p[@id='change']")
  end

  context 'with count' do
    it 'should be false if the content occurs the given number of times' do
      expect(@session).not_to have_no_xpath('//p', count: 3)
      expect(@session).not_to have_no_xpath("//p//a[@id='foo']", count: 1)
      expect(@session).not_to have_no_xpath("//p[contains(.,'est')]", count: 1)
      expect(@session).not_to have_no_xpath("//p//a[@id='doesnotexist']", count: 0)
    end

    it 'should be true if the content occurs a different number of times than the given' do
      expect(@session).to have_no_xpath('//p', count: 6)
      expect(@session).to have_no_xpath("//p//a[@id='foo']", count: 2)
      expect(@session).to have_no_xpath("//p[contains(.,'est')]", count: 5)
      expect(@session).to have_no_xpath("//p//a[@id='doesnotexist']", count: 1)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is contained' do
      expect(@session).not_to have_no_xpath('//p//a', text: 'Redirect', count: 1)
      expect(@session).to have_no_xpath('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is matched' do
      expect(@session).not_to have_no_xpath('//p//a', text: /re[dab]i/i, count: 1)
      expect(@session).to have_no_xpath('//p//a', text: /Red$/)
    end
  end
end
