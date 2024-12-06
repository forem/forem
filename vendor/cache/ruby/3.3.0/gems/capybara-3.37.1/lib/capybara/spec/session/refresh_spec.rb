# frozen_string_literal: true

# NOTE: This file uses `sleep` to sync up parts of the tests. This is only implemented like this
# because of the methods being tested. In tests using Capybara this type of behavior should be implemented
# using Capybara provided assertions with builtin waiting behavior.

Capybara::SpecHelper.spec '#refresh' do
  it 'reload the page' do
    @session.visit('/form')
    expect(@session).to have_select('form_locale', selected: 'English')
    @session.select('Swedish', from: 'form_locale')
    expect(@session).to have_select('form_locale', selected: 'Swedish')
    @session.refresh
    expect(@session).to have_select('form_locale', selected: 'English')
  end

  it 'raises any errors caught inside the server', requires: [:server] do
    quietly { @session.visit('/error') }
    expect do
      @session.refresh
    end.to raise_error(TestApp::TestAppError)
  end

  it 'it reposts' do
    @session.visit('/form')
    @session.select('Sweden', from: 'form_region')
    @session.click_button('awesome')
    sleep 2
    expect do
      @session.refresh
      sleep 2
    end.to change { extract_results(@session)['post_count'] }.by(1)
  end
end
