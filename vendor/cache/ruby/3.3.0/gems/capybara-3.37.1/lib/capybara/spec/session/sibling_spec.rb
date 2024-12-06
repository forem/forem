# frozen_string_literal: true

Capybara::SpecHelper.spec '#sibling' do
  before do
    @session.visit('/with_html')
  end

  after do
    Capybara::Selector.remove(:monkey)
  end

  it 'should find a prior sibling element using the given locator' do
    el = @session.find(:css, '#mid_sibling')
    expect(el.sibling('//div[@data-pre]')[:id]).to eq('pre_sibling')
  end

  it 'should find a following sibling element using the given locator' do
    el = @session.find(:css, '#mid_sibling')
    expect(el.sibling('//div[@data-post]')[:id]).to eq('post_sibling')
  end

  it 'should raise an error if there are multiple matches' do
    el = @session.find(:css, '#mid_sibling')
    expect { el.sibling('//div') }.to raise_error(Capybara::Ambiguous)
  end

  context 'with css selectors' do
    it 'should find the first element using the given locator' do
      el = @session.find(:css, '#mid_sibling')
      expect(el.sibling(:css, '#pre_sibling')).to have_text('Pre Sibling')
      expect(el.sibling(:css, '#post_sibling')).to have_text('Post Sibling')
    end
  end

  context 'with custom selector' do
    it 'should use the custom selector' do
      Capybara.add_selector(:data_attribute) do
        xpath { |attr| ".//*[@data-#{attr}]" }
      end
      el = @session.find(:css, '#mid_sibling')
      expect(el.sibling(:data_attribute, 'pre').text).to eq('Pre Sibling')
      expect(el.sibling(:data_attribute, 'post').text).to eq('Post Sibling')
    end
  end

  it 'should raise ElementNotFound with a useful default message if nothing was found' do
    el = @session.find(:css, '#child')
    expect do
      el.sibling(:xpath, '//div[@id="nosuchthing"]')
    end.to raise_error(Capybara::ElementNotFound, 'Unable to find xpath "//div[@id=\\"nosuchthing\\"]" that is a sibling of visible css "#child"')
  end
end
