# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_all_of_selectors' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given selectors are on the page' do
    @session.assert_all_of_selectors(:css, 'p a#foo', 'h2#h2one', 'h2#h2two')
  end

  it 'should be false if any of the given selectors are not on the page' do
    expect { @session.assert_all_of_selectors(:css, 'p a#foo', 'h2#h2three', 'h2#h2one') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect { @session.assert_all_of_selectors('p a#foo', 'h2#h2three', 'h2#h2one') }.to raise_error(Capybara::ElementNotFound)
    @session.assert_all_of_selectors('p a#foo', 'h2#h2two', 'h2#h2one')
  end

  it 'should support filter block' do
    expect { @session.assert_all_of_selectors(:css, 'h2#h2one', 'h2#h2two') { |n| n[:id] == 'h2one' } }.to raise_error(Capybara::ElementNotFound, /custom filter block/)
  end

  context 'should respect scopes' do
    it 'when used with `within`' do
      @session.within "//p[@id='first']" do
        @session.assert_all_of_selectors(".//a[@id='foo']")
        expect { @session.assert_all_of_selectors(".//a[@id='red']") }.to raise_error(Capybara::ElementNotFound)
      end
    end

    it 'when called on elements' do
      el = @session.find "//p[@id='first']"
      el.assert_all_of_selectors(".//a[@id='foo']")
      expect { el.assert_all_of_selectors(".//a[@id='red']") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with options' do
    it 'should apply options to all locators' do
      @session.assert_all_of_selectors(:field, 'normal', 'additional_newline', type: :textarea)
      expect { @session.assert_all_of_selectors(:field, 'normal', 'test_field', 'additional_newline', type: :textarea) }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with wait', requires: [:js] do
    it 'should not raise error if all the elements appear before given wait duration' do
      Capybara.using_wait_time(0.1) do
        @session.visit('/with_js')
        @session.click_link('Click me')
        @session.assert_all_of_selectors(:css, 'a#clickable', 'a#has-been-clicked', '#drag', wait: 1.5)
      end
    end
  end
end

Capybara::SpecHelper.spec '#assert_none_of_selectors' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if any of the given locators are on the page' do
    expect { @session.assert_none_of_selectors(:xpath, '//p', '//a') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_none_of_selectors(:xpath, '//abbr', '//a') }.to raise_error(Capybara::ElementNotFound)
    expect { @session.assert_none_of_selectors(:css, 'p a#foo') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should be true if none of the given locators are on the page' do
    @session.assert_none_of_selectors(:xpath, '//abbr', '//td')
    @session.assert_none_of_selectors(:css, 'p a#doesnotexist', 'abbr')
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    @session.assert_none_of_selectors('p a#doesnotexist', 'abbr')
    expect { @session.assert_none_of_selectors('abbr', 'p a#foo') }.to raise_error(Capybara::ElementNotFound)
  end

  context 'should respect scopes' do
    it 'when used with `within`' do
      @session.within "//p[@id='first']" do
        expect { @session.assert_none_of_selectors(".//a[@id='foo']") }.to raise_error(Capybara::ElementNotFound)
        @session.assert_none_of_selectors(".//a[@id='red']")
      end
    end

    it 'when called on an element' do
      el = @session.find "//p[@id='first']"
      expect { el.assert_none_of_selectors(".//a[@id='foo']") }.to raise_error(Capybara::ElementNotFound)
      el.assert_none_of_selectors(".//a[@id='red']")
    end
  end

  context 'with options' do
    it 'should apply the options to all locators' do
      expect { @session.assert_none_of_selectors('//p//a', text: 'Redirect') }.to raise_error(Capybara::ElementNotFound)
      @session.assert_none_of_selectors('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is matched' do
      expect { @session.assert_none_of_selectors('//p//a', text: /re[dab]i/i, count: 1) }.to raise_error(Capybara::ElementNotFound)
      @session.assert_none_of_selectors('//p//a', text: /Red$/)
    end
  end

  context 'with wait', requires: [:js] do
    it 'should not find elements if they appear after given wait duration' do
      @session.visit('/with_js')
      @session.click_link('Click me')
      @session.assert_none_of_selectors(:css, '#new_field', 'a#has-been-clicked', wait: 0.1)
    end
  end
end

Capybara::SpecHelper.spec '#assert_any_of_selectors' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if any of the given selectors are on the page' do
    @session.assert_any_of_selectors(:css, 'a#foo', 'h2#h2three')
    @session.assert_any_of_selectors(:css, 'h2#h2three', 'a#foo')
  end

  it 'should be false if none of the given selectors are on the page' do
    expect { @session.assert_any_of_selectors(:css, 'h2#h2three', 'h4#h4four') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect { @session.assert_any_of_selectors('h2#h2three', 'h5#h5five') }.to raise_error(Capybara::ElementNotFound)
    @session.assert_any_of_selectors('p a#foo', 'h2#h2two', 'h2#h2one')
  end

  it 'should support filter block' do
    expect { @session.assert_any_of_selectors(:css, 'h2#h2one', 'h2#h2two') { |_n| false } }.to raise_error(Capybara::ElementNotFound, /custom filter block/)
  end
end
