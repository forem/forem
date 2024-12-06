# frozen_string_literal: true

Capybara::SpecHelper.spec '#ancestor' do
  before do
    @session.visit('/with_html')
  end

  after do
    Capybara::Selector.remove(:monkey)
  end

  it 'should find the ancestor element using the given locator' do
    el = @session.find(:css, '#first_image')
    expect(el.ancestor('//p')).to have_text('Lorem ipsum dolor')
    expect(el.ancestor('//a')[:'aria-label']).to eq('Go to simple')
  end

  it 'should find the ancestor element using the given locator and options' do
    el = @session.find(:css, '#child')
    expect(el.ancestor('//div', text: "Ancestor\nAncestor\nAncestor")[:id]).to eq('ancestor3')
  end

  it 'should find the closest ancestor' do
    el = @session.find(:css, '#child')
    expect(el.ancestor('.//div', order: :reverse, match: :first)[:id]).to eq('ancestor1')
  end

  it 'should raise an error if there are multiple matches' do
    el = @session.find(:css, '#child')
    expect { el.ancestor('//div') }.to raise_error(Capybara::Ambiguous)
    expect { el.ancestor('//div', text: 'Ancestor') }.to raise_error(Capybara::Ambiguous)
  end

  context 'with css selectors' do
    it 'should find the first element using the given locator' do
      el = @session.find(:css, '#first_image')
      expect(el.ancestor(:css, 'p')).to have_text('Lorem ipsum dolor')
      expect(el.ancestor(:css, 'a')[:'aria-label']).to eq('Go to simple')
    end

    it 'should support pseudo selectors' do
      el = @session.find(:css, '#button_img')
      expect(el.ancestor(:css, 'button:disabled')[:id]).to eq('ancestor_button')
    end
  end

  context 'with xpath selectors' do
    it 'should find the first element using the given locator' do
      el = @session.find(:css, '#first_image')
      expect(el.ancestor(:xpath, '//p')).to have_text('Lorem ipsum dolor')
      expect(el.ancestor(:xpath, '//a')[:'aria-label']).to eq('Go to simple')
    end
  end

  context 'with custom selector' do
    it 'should use the custom selector' do
      Capybara.add_selector(:level) do
        xpath { |num| ".//*[@id='ancestor#{num}']" }
      end
      el = @session.find(:css, '#child')
      expect(el.ancestor(:level, 1)[:id]).to eq 'ancestor1'
      expect(el.ancestor(:level, 3)[:id]).to eq 'ancestor3'
    end
  end

  it 'should raise ElementNotFound with a useful default message if nothing was found' do
    el = @session.find(:css, '#child')
    expect do
      el.ancestor(:xpath, '//div[@id="nosuchthing"]')
    end.to raise_error(Capybara::ElementNotFound, 'Unable to find xpath "//div[@id=\\"nosuchthing\\"]" that is an ancestor of visible css "#child"')
  end

  context 'within a scope' do
    it 'should limit the ancestors to inside the scope' do
      @session.within(:css, '#ancestor2') do
        el = @session.find(:css, '#child')
        expect(el.ancestor(:css, 'div', text: 'Ancestor')[:id]).to eq('ancestor1')
      end
    end
  end

  it 'should raise if selector type is unknown' do
    el = @session.find(:css, '#child')
    expect do
      el.ancestor(:unknown, '//h1')
    end.to raise_error(ArgumentError)
  end
end
