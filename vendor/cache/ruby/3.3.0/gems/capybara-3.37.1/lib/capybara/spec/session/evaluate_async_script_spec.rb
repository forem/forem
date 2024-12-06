# frozen_string_literal: true

Capybara::SpecHelper.spec '#evaluate_async_script', requires: [:js] do
  it 'should evaluate the given script and return whatever it produces' do
    @session.visit('/with_js')
    expect(@session.evaluate_async_script('arguments[0](4)')).to eq(4)
  end

  it 'should support passing elements as arguments to the script', requires: %i[js es_args] do
    @session.visit('/with_js')
    el = @session.find(:css, '#drag p')
    result = @session.evaluate_async_script('arguments[2]([arguments[0].innerText, arguments[1]])', el, 'Doodle Funk')
    expect(result).to eq ['This is a draggable element.', 'Doodle Funk']
  end

  it 'should support returning elements after asynchronous operation', requires: %i[js es_args] do
    @session.visit('/with_js')
    @session.find(:css, '#change') # ensure page has loaded and element is available
    el = @session.evaluate_async_script("var cb = arguments[0]; setTimeout(function(){ cb(document.getElementById('change')) }, 100)")
    expect(el).to be_instance_of(Capybara::Node::Element)
    expect(el).to eq(@session.find(:css, '#change'))
  end
end
