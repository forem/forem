# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_selector?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given selector is on the page' do
    expect(@session).to have_selector(:xpath, '//p')
    expect(@session).to have_selector(:css, 'p a#foo')
    expect(@session).to have_selector("//p[contains(.,'est')]")
  end

  it 'should be false if the given selector is not on the page' do
    expect(@session).not_to have_selector(:xpath, '//abbr')
    expect(@session).not_to have_selector(:css, 'p a#doesnotexist')
    expect(@session).not_to have_selector("//p[contains(.,'thisstringisnotonpage')]")
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(@session).not_to have_selector('p a#doesnotexist')
    expect(@session).to have_selector('p a#foo')
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect(@session).to have_selector(".//a[@id='foo']")
      expect(@session).not_to have_selector(".//a[@id='red']")
    end
  end

  it 'should accept a filter block' do
    expect(@session).to have_selector(:css, 'a', count: 1) { |el| el[:id] == 'foo' }
  end

  context 'with count' do
    it 'should be true if the content is on the page the given number of times' do
      expect(@session).to have_selector('//p', count: 3)
      expect(@session).to have_selector("//p//a[@id='foo']", count: 1)
      expect(@session).to have_selector("//p[contains(.,'est')]", count: 1)
    end

    it 'should be false if the content is on the page the given number of times' do
      expect(@session).not_to have_selector('//p', count: 6)
      expect(@session).not_to have_selector("//p//a[@id='foo']", count: 2)
      expect(@session).not_to have_selector("//p[contains(.,'est')]", count: 5)
    end

    it "should be false if the content isn't on the page at all" do
      expect(@session).not_to have_selector('//abbr', count: 2)
      expect(@session).not_to have_selector("//p//a[@id='doesnotexist']", count: 1)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      expect(@session).to have_selector('//p//a', text: 'Redirect', count: 1)
      expect(@session).to have_selector(:css, 'p a', text: 'Redirect', count: 1)
      expect(@session).not_to have_selector('//p', text: 'Doesnotexist')
    end

    it 'should respect visibility setting' do
      expect(@session).to have_selector(:id, 'hidden-text', text: 'Some of this text is hidden!', visible: :all)
      expect(@session).not_to have_selector(:id, 'hidden-text', text: 'Some of this text is hidden!', visible: :visible)
      Capybara.ignore_hidden_elements = false
      expect(@session).to have_selector(:id, 'hidden-text', text: 'Some of this text is hidden!', visible: :all)
      Capybara.visible_text_only = true
      expect(@session).not_to have_selector(:id, 'hidden-text', text: 'Some of this text is hidden!', visible: :visible)
    end

    it 'should discard all matches where the given regexp is not matched' do
      expect(@session).to have_selector('//p//a', text: /re[dab]i/i, count: 1)
      expect(@session).not_to have_selector('//p//a', text: /Red$/)
    end

    it 'should raise when extra parameters passed' do
      expect do
        expect(@session).to have_selector(:css, 'p a#foo', 'extra')
      end.to raise_error ArgumentError, /extra/
    end

    context 'with whitespace normalization' do
      context 'Capybara.default_normalize_ws = false' do
        it 'should support normalize_ws option' do
          Capybara.default_normalize_ws = false
          expect(@session).not_to have_selector(:id, 'second', text: 'text with whitespace')
          expect(@session).to have_selector(:id, 'second', text: 'text with whitespace', normalize_ws: true)
        end
      end

      context 'Capybara.default_normalize_ws = true' do
        it 'should support normalize_ws option' do
          Capybara.default_normalize_ws = true
          expect(@session).to have_selector(:id, 'second', text: 'text with whitespace')
          expect(@session).not_to have_selector(:id, 'second', text: 'text with whitespace', normalize_ws: false)
        end
      end
    end
  end

  context 'with exact_text' do
    context 'string' do
      it 'should only match elements that match exactly' do
        expect(@session).to have_selector(:id, 'h2one', exact_text: 'Header Class Test One')
        expect(@session).to have_no_selector(:id, 'h2one', exact_text: 'Header Class Test')
      end
    end

    context 'boolean' do
      it 'should only match elements that match exactly when true' do
        expect(@session).to have_selector(:id, 'h2one', text: 'Header Class Test One', exact_text: true)
        expect(@session).to have_no_selector(:id, 'h2one', text: 'Header Class Test', exact_text: true)
      end

      it 'should match substrings when false' do
        expect(@session).to have_selector(:id, 'h2one', text: 'Header Class Test One', exact_text: false)
        expect(@session).to have_selector(:id, 'h2one', text: 'Header Class Test', exact_text: false)
      end

      it 'should warn if text option is a regexp that it is ignoring exact_text' do
        allow(Capybara::Helpers).to receive(:warn)
        expect(@session).to have_selector(:id, 'h2one', text: /Class Test/, exact_text: true)
        expect(Capybara::Helpers).to have_received(:warn).with(/'exact_text' option is not supported/)
      end
    end

    context 'regexp' do
      it 'should only match when it fully matches' do
        expect(@session).to have_selector(:id, 'h2one', exact_text: /Header Class Test One/)
        expect(@session).to have_no_selector(:id, 'h2one', exact_text: /Header Class Test/)
        expect(@session).to have_no_selector(:id, 'h2one', exact_text: /Class Test One/)
        expect(@session).to have_no_selector(:id, 'h2one', exact_text: /Class Test/)
      end
    end
  end

  context 'datalist' do
    it 'should match options' do
      @session.visit('/form')
      expect(@session).to have_selector(:datalist_input, with_options: %w[Jaguar Audi Mercedes])
      expect(@session).not_to have_selector(:datalist_input, with_options: %w[Ford Chevy])
    end
  end
end

Capybara::SpecHelper.spec '#has_no_selector?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given selector is on the page' do
    expect(@session).not_to have_no_selector(:xpath, '//p')
    expect(@session).not_to have_no_selector(:css, 'p a#foo')
    expect(@session).not_to have_no_selector("//p[contains(.,'est')]")
  end

  it 'should be true if the given selector is not on the page' do
    expect(@session).to have_no_selector(:xpath, '//abbr')
    expect(@session).to have_no_selector(:css, 'p a#doesnotexist')
    expect(@session).to have_no_selector("//p[contains(.,'thisstringisnotonpage')]")
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(@session).to have_no_selector('p a#doesnotexist')
    expect(@session).not_to have_no_selector('p a#foo')
  end

  it 'should respect scopes' do
    @session.within "//p[@id='first']" do
      expect(@session).not_to have_no_selector(".//a[@id='foo']")
      expect(@session).to have_no_selector(".//a[@id='red']")
    end
  end

  it 'should accept a filter block' do
    expect(@session).to have_no_selector(:css, 'a#foo') { |el| el[:id] != 'foo' }
  end

  context 'with count' do
    it 'should be false if the content is on the page the given number of times' do
      expect(@session).not_to have_no_selector('//p', count: 3)
      expect(@session).not_to have_no_selector("//p//a[@id='foo']", count: 1)
      expect(@session).not_to have_no_selector("//p[contains(.,'est')]", count: 1)
    end

    it 'should be true if the content is on the page the wrong number of times' do
      expect(@session).to have_no_selector('//p', count: 6)
      expect(@session).to have_no_selector("//p//a[@id='foo']", count: 2)
      expect(@session).to have_no_selector("//p[contains(.,'est')]", count: 5)
    end

    it "should be true if the content isn't on the page at all" do
      expect(@session).to have_no_selector('//abbr', count: 2)
      expect(@session).to have_no_selector("//p//a[@id='doesnotexist']", count: 1)
    end
  end

  context 'with text' do
    it 'should discard all matches where the given string is contained' do
      expect(@session).not_to have_no_selector('//p//a', text: 'Redirect', count: 1)
      expect(@session).to have_no_selector('//p', text: 'Doesnotexist')
    end

    it 'should discard all matches where the given regexp is matched' do
      expect(@session).not_to have_no_selector('//p//a', text: /re[dab]i/i, count: 1)
      expect(@session).to have_no_selector('//p//a', text: /Red$/)
    end

    it 'should error when matching element exists' do
      expect do
        expect(@session).to have_no_selector('//h2', text: 'Header Class Test Five')
      end.to raise_error RSpec::Expectations::ExpectationNotMetError
    end
  end
end
