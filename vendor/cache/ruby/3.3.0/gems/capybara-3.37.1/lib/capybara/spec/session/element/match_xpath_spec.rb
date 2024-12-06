# frozen_string_literal: true

Capybara::SpecHelper.spec '#match_xpath?' do
  before do
    @session.visit('/with_html')
    @element = @session.find(:css, 'span.number')
  end

  it 'should be true if the given selector is on the page' do
    expect(@element).to match_xpath('//span')
    expect(@element).to match_xpath("//span[@class='number']")
  end

  it 'should be false if the given selector is not on the page' do
    expect(@element).not_to match_xpath('//abbr')
    expect(@element).not_to match_xpath('//div')
    expect(@element).not_to match_xpath("//span[@class='not_a_number']")
  end

  it 'should use xpath even if default selector is CSS' do
    Capybara.default_selector = :css
    expect(@element).not_to have_xpath("//span[@class='not_a_number']")
    expect(@element).not_to have_xpath("//div[@class='number']")
  end
end
