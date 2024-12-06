# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_selector' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given selector is on the page' do
    @session.assert_selector(:xpath, '//p')
    @session.assert_selector(:css, 'p a#foo')
    @session.assert_selector("//p[contains(.,'est')]")
  end

  it 'should be false if the given selector is not on the page' do
    expect { @session.assert_selector(:xpath, '//abbr') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_selector(:css, 'p a#doesnotexist') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_selector("//p[contains(.,'thisstringisnotonpage')]") }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect { @session.assert_selector('p a#doesnotexist') }.to raise_error(Capybara::ElementNotFound)
    @session.assert_selector('p a#foo')
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      @session.assert_selector(".//a[@id='foo']")
      expect { @session.assert_selector(".//a[@id='red']") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with count' do
    it 'should be true if the content is on the page the given number of times' do
      @session.assert_selector('//p', count: 3)
      @session.assert_selector("//p//a[@id='foo']", count: 1)
      @session.assert_selector("//p[contains(.,'est')]", count: 1)
    end

    it 'should be false if the content is on the page the given number of times' do
      expect { @session.assert_selector('//p', count: 6) }.to raise_error(Capybara::ElementNotFound)
      expect { @session.assert_selector("//p//a[@id='foo']", count: 2) }.to raise_error(Capybara::ElementNotFound)
      expect { @session.assert_selector("//p[contains(.,'est')]", count: 5) }.to raise_error(Capybara::ElementNotFound)
    end

    it "should be false if the content isn't on the page at all" do
      expect { @session.assert_selector('//abbr', count: 2) }.to raise_error(Capybara::ElementNotFound)
      expect { @session.assert_selector("//p//a[@id='doesnotexist']", count: 1) }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      @session.assert_selector('//p//a', text: 'Redirect', count: 1)
      expect { @session.assert_selector('//p', text: 'Doesnotexist') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'should discard all matches where the given regexp is not matched' do
      @session.assert_selector('//p//a', text: /re[dab]i/i, count: 1)
      expect { @session.assert_selector('//p//a', text: /Red$/) }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with wait', requires: [:js] do
    it 'should find element if it appears before given wait duration' do
      Capybara.using_wait_time(0.1) do
        @session.visit('/with_js')
        @session.click_link('Click me')
        @session.assert_selector(:css, 'a#has-been-clicked', text: 'Has been clicked', wait: 2)
      end
    end
  end
end

Capybara::SpecHelper.spec '#assert_no_selector' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given selector is on the page' do
    expect { @session.assert_no_selector(:xpath, '//p') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_no_selector(:css, 'p a#foo') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_no_selector("//p[contains(.,'est')]") }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should be true if the given selector is not on the page' do
    @session.assert_no_selector(:xpath, '//abbr')
    @session.assert_no_selector(:css, 'p a#doesnotexist')
    @session.assert_no_selector("//p[contains(.,'thisstringisnotonpage')]")
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    @session.assert_no_selector('p a#doesnotexist')
    expect { @session.assert_no_selector('p a#foo') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect { @session.assert_no_selector(".//a[@id='foo']") }.to raise_error(Capybara::ElementNotFound)
      @session.assert_no_selector(".//a[@id='red']")
    end
  end

  context 'with count' do
    it 'should be false if the content is on the page the given number of times' do
      expect { @session.assert_no_selector('//p', count: 3) }.to raise_error(Capybara::ElementNotFound)
      expect { @session.assert_no_selector("//p//a[@id='foo']", count: 1) }.to raise_error(Capybara::ElementNotFound)
      expect { @session.assert_no_selector("//p[contains(.,'est')]", count: 1) }.to raise_error(Capybara::ElementNotFound)
    end

    it 'should be true if the content is on the page the wrong number of times' do
      @session.assert_no_selector('//p', count: 6)
      @session.assert_no_selector("//p//a[@id='foo']", count: 2)
      @session.assert_no_selector("//p[contains(.,'est')]", count: 5)
    end

    it "should be true if the content isn't on the page at all" do
      @session.assert_no_selector('//abbr', count: 2)
      @session.assert_no_selector("//p//a[@id='doesnotexist']", count: 1)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is contained' do
      expect { @session.assert_no_selector('//p//a', text: 'Redirect', count: 1) }.to raise_error(Capybara::ElementNotFound)
      @session.assert_no_selector('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is matched' do
      expect { @session.assert_no_selector('//p//a', text: /re[dab]i/i, count: 1) }.to raise_error(Capybara::ElementNotFound)
      @session.assert_no_selector('//p//a', text: /Red$/)
    end
  end

  context 'with wait', requires: [:js] do
    it 'should not find element if it appears after given wait duration' do
      @session.visit('/with_js')
      @session.click_link('Click me')
      @session.assert_no_selector(:css, 'a#has-been-clicked', text: 'Has been clicked', wait: 0.1)
    end
  end
end
