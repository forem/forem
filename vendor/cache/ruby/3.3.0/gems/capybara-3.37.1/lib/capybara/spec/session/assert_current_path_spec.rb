# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_current_path' do
  before do
    @session.visit('/with_js')
  end

  it 'should not raise if the page has the given current path' do
    expect { @session.assert_current_path('/with_js') }.not_to raise_error
  end

  it 'should allow regexp matches' do
    expect { @session.assert_current_path(/w[a-z]{3}_js/) }.not_to raise_error
  end

  it 'should wait for current_path', requires: [:js] do
    @session.click_link('Change page')
    expect { @session.assert_current_path('/with_html') }.not_to raise_error
  end

  it 'should raise if the page has not the given current_path' do
    expect { @session.assert_current_path('/with_html') }.to raise_error(Capybara::ExpectationNotMet, 'expected "/with_js" to equal "/with_html"')
  end

  it 'should check query options' do
    @session.visit('/with_js?test=test')
    expect { @session.assert_current_path('/with_js?test=test') }.not_to raise_error
  end

  it 'should compare the full url' do
    expect { @session.assert_current_path(%r{\Ahttp://[^/]*/with_js\Z}, url: true) }.not_to raise_error
  end

  it 'should ignore the query' do
    @session.visit('/with_js?test=test')
    expect { @session.assert_current_path('/with_js', ignore_query: true) }.not_to raise_error
  end

  it 'should not cause an exception when current_url is nil' do
    allow(@session).to receive(:current_url).and_return(nil)
    allow(@session.page).to receive(:current_url).and_return(nil) if @session.respond_to? :page

    expect { @session.assert_current_path(nil) }.not_to raise_error
  end
end

Capybara::SpecHelper.spec '#assert_no_current_path?' do
  before do
    @session.visit('/with_js')
  end

  it 'should raise if the page has the given current_path' do
    expect { @session.assert_no_current_path('/with_js') }.to raise_error(Capybara::ExpectationNotMet)
  end

  it 'should allow regexp matches' do
    expect { @session.assert_no_current_path(/monkey/) }.not_to raise_error
  end

  it 'should wait for current_path to disappear', requires: [:js] do
    @session.click_link('Change page')
    expect { @session.assert_no_current_path('/with_js') }.not_to raise_error
  end

  it 'should not raise if the page has not the given current_path' do
    expect { @session.assert_no_current_path('/with_html') }.not_to raise_error
  end

  it 'should not cause an exception when current_url is nil' do
    allow(@session).to receive(:current_url).and_return(nil)
    allow(@session.page).to receive(:current_url).and_return(nil) if @session.respond_to? :page

    expect { @session.assert_no_current_path('/with_html') }.not_to raise_error
  end
end
