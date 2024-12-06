# frozen_string_literal: true

Capybara::SpecHelper.spec '#response_headers' do
  it 'should return response headers', requires: [:response_headers] do
    @session.visit('/with_simple_html')
    expect(@session.response_headers['Content-Type']).to match %r{text/html}
  end
end
