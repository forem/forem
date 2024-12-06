# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_link?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given link is on the page' do
    expect(@session).to have_link('foo')
    expect(@session).to have_link('awesome title')
    expect(@session).to have_link('A link', href: '/with_simple_html')
    expect(@session).to have_link(:'A link', href: :'/with_simple_html')
    expect(@session).to have_link('A link', href: %r{/with_simple_html})
  end

  it 'should be false if the given link is not on the page' do
    expect(@session).not_to have_link('monkey')
    expect(@session).not_to have_link('A link', href: '/nonexistent-href')
    expect(@session).not_to have_link('A link', href: /nonexistent/)
  end

  it 'should notify if an invalid locator is specified' do
    allow(Capybara::Helpers).to receive(:warn).and_return(nil)
    @session.has_link?(@session)
    expect(Capybara::Helpers).to have_received(:warn).with(/Called from: .+/)
  end

  context 'with focused:', requires: [:active_element] do
    it 'should be true if the given link is on the page and has focus' do
      @session.send_keys(:tab)

      expect(@session).to have_link('labore', focused: true)
    end

    it 'should be false if the given link is on the page and does not have focus' do
      expect(@session).to have_link('labore', focused: false)
    end
  end
end

Capybara::SpecHelper.spec '#has_no_link?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given link is on the page' do
    expect(@session).not_to have_no_link('foo')
    expect(@session).not_to have_no_link('awesome title')
    expect(@session).not_to have_no_link('A link', href: '/with_simple_html')
  end

  it 'should be true if the given link is not on the page' do
    expect(@session).to have_no_link('monkey')
    expect(@session).to have_no_link('A link', href: '/nonexistent-href')
    expect(@session).to have_no_link('A link', href: %r{/nonexistent-href})
  end

  context 'with focused:', requires: [:active_element] do
    it 'should be true if the given link is on the page and has focus' do
      expect(@session).to have_no_link('labore', focused: true)
    end

    it 'should be false if the given link is on the page and does not have focus' do
      @session.send_keys(:tab)

      expect(@session).to have_no_link('labore', focused: false)
    end
  end
end
