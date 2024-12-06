# frozen_string_literal: true

Capybara::SpecHelper.spec '#text' do
  it 'should print the text of the page' do
    @session.visit('/with_simple_html')
    expect(@session.text).to eq('Bar')
  end

  it 'ignores invisible text by default' do
    @session.visit('/with_html')
    expect(@session.find(:id, 'hidden-text').text).to eq('Some of this text is')
  end

  it 'shows invisible text if `:all` given' do
    @session.visit('/with_html')
    expect(@session.find(:id, 'hidden-text').text(:all)).to eq('Some of this text is hidden!')
  end

  it 'ignores invisible text if `:visible` given' do
    Capybara.ignore_hidden_elements = false
    @session.visit('/with_html')
    expect(@session.find(:id, 'hidden-text').text(:visible)).to eq('Some of this text is')
  end

  it 'ignores invisible text if `Capybara.ignore_hidden_elements = true`' do
    @session.visit('/with_html')
    expect(@session.find(:id, 'hidden-text').text).to eq('Some of this text is')
    Capybara.ignore_hidden_elements = false
    expect(@session.find(:id, 'hidden-text').text).to eq('Some of this text is hidden!')
  end

  it 'ignores invisible text if `Capybara.visible_text_only = true`' do
    @session.visit('/with_html')
    Capybara.visible_text_only = true
    expect(@session.find(:id, 'hidden-text').text).to eq('Some of this text is')
    Capybara.ignore_hidden_elements = false
    expect(@session.find(:id, 'hidden-text').text).to eq('Some of this text is')
  end

  it 'ignores invisible text if ancestor is invisible' do
    @session.visit('/with_html')
    expect(@session.find(:id, 'hidden_via_ancestor', visible: false).text).to eq('')
  end

  context 'with css as default selector' do
    before { Capybara.default_selector = :css }

    after { Capybara.default_selector = :xpath }

    it 'should print the text of the page' do
      @session.visit('/with_simple_html')
      expect(@session.text).to eq('Bar')
    end
  end

  it 'should be correctly normalized when visible' do
    @session.visit('/with_html')
    el = @session.find(:css, '#normalized')
    expect(el.text).to eq "Some text\nMore text\nAnd more text\nEven more    text on multiple lines"
  end

  it 'should be a textContent with irrelevant whitespace collapsed when non-visible' do
    @session.visit('/with_html')
    el = @session.find(:css, '#non_visible_normalized', visible: false)
    expect(el.text(:all)).to eq 'Some textMore text And more text Even more    text on multiple lines'
  end

  it 'should strip correctly' do
    @session.visit('/with_html')
    el = @session.find(:css, '#ws')
    expect(el.text).to eq ' '
    expect(el.text(:all)).to eq ' '
  end
end
