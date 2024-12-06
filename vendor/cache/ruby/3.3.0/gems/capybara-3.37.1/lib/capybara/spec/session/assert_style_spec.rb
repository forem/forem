# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_matches_style', requires: [:css] do
  it 'should not raise if the elements style contains the given properties' do
    @session.visit('/with_html')
    expect do
      @session.find(:css, '#first').assert_matches_style(display: 'block')
    end.not_to raise_error
  end

  it "should raise error if the elements style doesn't contain the given properties" do
    @session.visit('/with_html')
    expect do
      @session.find(:css, '#first').assert_matches_style(display: 'inline')
    end.to raise_error(Capybara::ExpectationNotMet, 'Expected node to have styles {"display"=>"inline"}. Actual styles were {"display"=>"block"}')
  end

  it 'should wait for style', requires: %i[css js] do
    @session.visit('/with_js')
    el = @session.find(:css, '#change')
    @session.click_link('Change size')
    expect do
      el.assert_matches_style({ 'font-size': '50px' }, wait: 3)
    end.not_to raise_error
  end
end
