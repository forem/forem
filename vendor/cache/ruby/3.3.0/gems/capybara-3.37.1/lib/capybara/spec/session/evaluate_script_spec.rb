# frozen_string_literal: true

Capybara::SpecHelper.spec '#evaluate_script', requires: [:js] do
  it 'should evaluate the given script and return whatever it produces' do
    @session.visit('/with_js')
    expect(@session.evaluate_script('1+3')).to eq(4)
  end

  it 'should ignore leading whitespace' do
    @session.visit('/with_js')
    expect(@session.evaluate_script('
      1 + 3
    ')).to eq(4)
  end

  it 'should pass arguments to the script', requires: %i[js es_args] do
    @session.visit('/with_js')
    expect(@session).to have_css('#change')
    @session.evaluate_script("document.getElementById('change').textContent = arguments[0]", 'Doodle Funk')
    expect(@session).to have_css('#change', text: 'Doodle Funk')
  end

  it 'should support passing elements as arguments to the script', requires: %i[js es_args] do
    @session.visit('/with_js')
    el = @session.find(:css, '#change')
    @session.evaluate_script('arguments[0].textContent = arguments[1]', el, 'Doodle Funk')
    expect(@session).to have_css('#change', text: 'Doodle Funk')
  end

  it 'should support returning elements', requires: %i[js es_args] do
    @session.visit('/with_js')
    @session.find(:css, '#change') # ensure page has loaded and element is available
    el = @session.evaluate_script("document.getElementById('change')")
    expect(el).to be_instance_of(Capybara::Node::Element)
    expect(el).to eq(@session.find(:css, '#change'))
  end

  it 'should support multi statement via IIFE' do
    @session.visit('/with_js')
    @session.find(:css, '#change')
    el = @session.evaluate_script(<<~JS)
      (function(){
        var el = document.getElementById('change');
        return el;
      })()
    JS
    expect(el).to eq(@session.find(:css, '#change'))
  end
end
