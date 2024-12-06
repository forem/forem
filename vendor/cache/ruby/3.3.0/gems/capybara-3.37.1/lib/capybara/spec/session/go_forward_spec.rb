# frozen_string_literal: true

Capybara::SpecHelper.spec '#go_forward', requires: [:js] do
  it 'should fetch a response from the driver from the previous page' do
    @session.visit('/')
    expect(@session).to have_content('Hello world!')
    @session.visit('/foo')
    expect(@session).to have_content('Another World')
    @session.go_back
    expect(@session).to have_content('Hello world!')
    @session.go_forward
    expect(@session).to have_content('Another World')
  end
end
