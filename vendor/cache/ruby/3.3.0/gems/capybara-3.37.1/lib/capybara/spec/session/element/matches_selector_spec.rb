# frozen_string_literal: true

Capybara::SpecHelper.spec '#match_selector?' do
  let(:element) { @session.find(:xpath, '//span', text: '42') }

  before do
    @session.visit('/with_html')
  end

  it 'should be true if the element matches the given selector' do
    expect(element).to match_selector(:xpath, '//span')
    expect(element).to match_selector(:css, 'span.number')
    expect(element.matches_selector?(:css, 'span.number')).to be true
  end

  it 'should be false if the element does not match the given selector' do
    expect(element).not_to match_selector(:xpath, '//div')
    expect(element).not_to match_selector(:css, 'span.not_a_number')
    expect(element.matches_selector?(:css, 'span.not_a_number')).to be false
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(element).not_to match_selector('span.not_a_number')
    expect(element).to match_selector('span.number')
  end

  it 'should work with elements located via a sibling selector' do
    sibling = element.sibling(:css, 'span', text: 'Other span')
    expect(sibling).to match_selector(:xpath, '//span')
    expect(sibling).to match_selector(:css, 'span')
  end

  it 'should work with the html element' do
    html = @session.find('/html')
    expect(html).to match_selector(:css, 'html')
  end

  context 'with text' do
    it 'should discard all matches where the given string is not contained' do
      expect(element).to match_selector('//span', text: '42')
      expect(element).not_to match_selector('//span', text: 'Doesnotexist')
    end
  end

  it 'should have css sugar' do
    expect(element.matches_css?('span.number')).to be true
    expect(element.matches_css?('span.not_a_number')).to be false
    expect(element.matches_css?('span.number', text: '42')).to be true
    expect(element.matches_css?('span.number', text: 'Nope')).to be false
  end

  it 'should have xpath sugar' do
    expect(element.matches_xpath?('//span')).to be true
    expect(element.matches_xpath?('//div')).to be false
    expect(element.matches_xpath?('//span', text: '42')).to be true
    expect(element.matches_xpath?('//span', text: 'Nope')).to be false
  end

  it 'should accept selector filters' do
    @session.visit('/form')
    cbox = @session.find(:css, '#form_pets_dog')
    expect(cbox.matches_selector?(:checkbox, id: 'form_pets_dog', option: 'dog', name: 'form[pets][]', checked: true)).to be true
  end

  it 'should accept a custom filter block' do
    @session.visit('/form')
    cbox = @session.find(:css, '#form_pets_dog')
    expect(cbox).to match_selector(:checkbox) { |node| node[:id] == 'form_pets_dog' }
    expect(cbox).not_to match_selector(:checkbox) { |node| node[:id] != 'form_pets_dog' }
    expect(cbox.matches_selector?(:checkbox) { |node| node[:id] == 'form_pets_dog' }).to be true
    expect(cbox.matches_selector?(:checkbox) { |node| node[:id] != 'form_pets_dog' }).to be false
  end
end

Capybara::SpecHelper.spec '#not_matches_selector?' do
  let(:element) { @session.find(:css, 'span', text: 42) }
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given selector matches the element' do
    expect(element).not_to not_match_selector(:xpath, '//span')
    expect(element).not_to not_match_selector(:css, 'span.number')
    expect(element.not_matches_selector?(:css, 'span.number')).to be false
  end

  it 'should be true if the given selector does not match the element' do
    expect(element).to not_match_selector(:xpath, '//abbr')
    expect(element).to not_match_selector(:css, 'p a#doesnotexist')
    expect(element.not_matches_selector?(:css, 'p a#doesnotexist')).to be true
  end

  it 'should use default selector' do
    Capybara.default_selector = :css
    expect(element).to not_match_selector('p a#doesnotexist')
    expect(element).not_to not_match_selector('span.number')
  end

  context 'with text' do
    it 'should discard all matches where the given string is contained' do
      expect(element).not_to not_match_selector(:css, 'span.number', text: '42')
      expect(element).to not_match_selector(:css, 'span.number', text: 'Doesnotexist')
    end
  end

  it 'should have CSS sugar' do
    expect(element.not_matches_css?('span.number')).to be false
    expect(element.not_matches_css?('p a#doesnotexist')).to be true
    expect(element.not_matches_css?('span.number', text: '42')).to be false
    expect(element.not_matches_css?('span.number', text: 'Doesnotexist')).to be true
  end

  it 'should have xpath sugar' do
    expect(element.not_matches_xpath?('//span')).to be false
    expect(element.not_matches_xpath?('//div')).to be true
    expect(element.not_matches_xpath?('//span', text: '42')).to be false
    expect(element.not_matches_xpath?('//span', text: 'Doesnotexist')).to be true
  end
end
