# frozen_string_literal: true

Capybara::SpecHelper.spec '#scroll_to', requires: [:scroll] do
  before do
    @session.visit('/scroll')
  end

  it 'can scroll an element to the top of the viewport' do
    el = @session.find(:css, '#scroll')
    @session.scroll_to(el, align: :top)
    expect(el.evaluate_script('this.getBoundingClientRect().top')).to be_within(1).of(0)
  end

  it 'can scroll an element to the bottom of the viewport' do
    el = @session.find(:css, '#scroll')
    @session.scroll_to(el, align: :bottom)
    el_bottom = el.evaluate_script('this.getBoundingClientRect().bottom')
    viewport_bottom = el.evaluate_script('document.documentElement.clientHeight')
    expect(el_bottom).to be_within(1).of(viewport_bottom)
  end

  it 'can scroll an element to the center of the viewport' do
    el = @session.find(:css, '#scroll')
    @session.scroll_to(el, align: :center)
    el_center = el.evaluate_script('(function(rect){return (rect.top + rect.bottom)/2})(this.getBoundingClientRect())')
    viewport_bottom = el.evaluate_script('document.documentElement.clientHeight')
    expect(el_center).to be_within(2).of(viewport_bottom / 2)
  end

  it 'can scroll the window to the vertical top' do
    @session.scroll_to :bottom
    @session.scroll_to :top
    expect(@session.evaluate_script('[window.scrollX || window.pageXOffset, window.scrollY || window.pageYOffset]')).to eq [0, 0]
  end

  it 'can scroll the window to the vertical bottom' do
    @session.scroll_to :bottom
    max_scroll = @session.evaluate_script('document.documentElement.scrollHeight - document.documentElement.clientHeight')
    expect(@session.evaluate_script('[window.scrollX || window.pageXOffset, window.scrollY || window.pageYOffset]')).to eq [0, max_scroll]
  end

  it 'can scroll the window to the vertical center' do
    @session.scroll_to :center
    max_scroll = @session.evaluate_script('document.documentElement.scrollHeight - document.documentElement.clientHeight')
    expect(@session.evaluate_script('[window.scrollX || window.pageXOffset, window.scrollY || window.pageYOffset]')).to eq [0, max_scroll / 2]
  end

  it 'can scroll the window to specific location' do
    @session.scroll_to 100, 100
    expect(@session.evaluate_script('[window.scrollX || window.pageXOffset, window.scrollY || window.pageYOffset]')).to eq [100, 100]
  end

  it 'can scroll an element to the top of the scrolling element' do
    scrolling_element = @session.find(:css, '#scrollable')
    el = scrolling_element.find(:css, '#inner')
    scrolling_element.scroll_to(el, align: :top)
    scrolling_element_top = scrolling_element.evaluate_script('this.getBoundingClientRect().top')
    expect(el.evaluate_script('this.getBoundingClientRect().top')).to be_within(3).of(scrolling_element_top)
  end

  it 'can scroll an element to the bottom of the scrolling element' do
    scrolling_element = @session.find(:css, '#scrollable')
    el = scrolling_element.find(:css, '#inner')
    scrolling_element.scroll_to(el, align: :bottom)
    el_bottom = el.evaluate_script('this.getBoundingClientRect().bottom')
    scroller_bottom = scrolling_element.evaluate_script('this.getBoundingClientRect().top + this.clientHeight')
    expect(el_bottom).to be_within(1).of(scroller_bottom)
  end

  it 'can scroll an element to the center of the scrolling element' do
    scrolling_element = @session.find(:css, '#scrollable')
    el = scrolling_element.find(:css, '#inner')
    scrolling_element.scroll_to(el, align: :center)
    el_center = el.evaluate_script('(function(rect){return (rect.top + rect.bottom)/2})(this.getBoundingClientRect())')
    scrollable_center = scrolling_element.evaluate_script('(this.clientHeight / 2) + this.getBoundingClientRect().top')
    expect(el_center).to be_within(1).of(scrollable_center)
  end

  it 'can scroll the scrolling element to the top' do
    scrolling_element = @session.find(:css, '#scrollable')
    scrolling_element.scroll_to :bottom
    scrolling_element.scroll_to :top
    expect(scrolling_element.evaluate_script('[this.scrollLeft, this.scrollTop]')).to eq [0, 0]
  end

  it 'can scroll the scrolling element to the bottom' do
    scrolling_element = @session.find(:css, '#scrollable')
    scrolling_element.scroll_to :bottom
    max_scroll = scrolling_element.evaluate_script('this.scrollHeight - this.clientHeight')
    expect(scrolling_element.evaluate_script('[this.scrollLeft, this.scrollTop]')).to eq [0, max_scroll]
  end

  it 'can scroll the scrolling element to the vertical center' do
    scrolling_element = @session.find(:css, '#scrollable')
    scrolling_element.scroll_to :center
    max_scroll = scrolling_element.evaluate_script('this.scrollHeight - this.clientHeight')
    expect(scrolling_element.evaluate_script('[this.scrollLeft, this.scrollTop]')).to eq [0, max_scroll / 2]
  end

  it 'can scroll the scrolling element to specific location' do
    scrolling_element = @session.find(:css, '#scrollable')
    scrolling_element.scroll_to 100, 100
    expect(scrolling_element.evaluate_script('[this.scrollLeft, this.scrollTop]')).to eq [100, 100]
  end

  it 'can scroll the window by a specific amount' do
    @session.scroll_to(:current, offset: [50, 75])
    expect(@session.evaluate_script('[window.scrollX || window.pageXOffset, window.scrollY || window.pageYOffset]')).to eq [50, 75]
  end

  it 'can scroll the scroll the scrolling element by a specific amount' do
    scrolling_element = @session.find(:css, '#scrollable')
    scrolling_element.scroll_to 100, 100
    scrolling_element.scroll_to(:current, offset: [-50, 50])
    expect(scrolling_element.evaluate_script('[this.scrollLeft, this.scrollTop]')).to eq [50, 150]
  end
end
