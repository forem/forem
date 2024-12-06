# frozen_string_literal: true

Capybara::SpecHelper.spec '#status_code' do
  it 'should return response codes', requires: [:status_code] do
    @session.visit('/with_simple_html')
    expect(@session.status_code).to eq(200)
  end
end
