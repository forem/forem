# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_title?' do
  before do
    @session.visit('/with_js')
  end

  it 'should be true if the page has the given title' do
    expect(@session).to have_title('with_js')
    expect(@session.has_title?('with_js')).to be true
  end

  it 'should allow regexp matches' do
    expect(@session).to have_title(/w[a-z]{3}_js/)
    expect(@session).not_to have_title(/monkey/)
  end

  it 'should wait for title', requires: [:js] do
    @session.click_link('Change title')
    expect(@session).to have_title('changed title')
  end

  it 'should be false if the page has not the given title' do
    expect(@session).not_to have_title('monkey')
    expect(@session.has_title?('monkey')).to be false
  end

  it 'should default to exact: false matching' do
    expect(@session).to have_title('with_js', exact: false)
    expect(@session).to have_title('with_', exact: false)
  end

  it 'should match exactly if exact: true option passed' do
    expect(@session).to have_title('with_js', exact: true)
    expect(@session).not_to have_title('with_', exact: true)
    expect(@session.has_title?('with_js', exact: true)).to be true
    expect(@session.has_title?('with_', exact: true)).to be false
  end

  it 'should match partial if exact: false option passed' do
    expect(@session).to have_title('with_js', exact: false)
    expect(@session).to have_title('with_', exact: false)
  end
end

Capybara::SpecHelper.spec '#has_no_title?' do
  before do
    @session.visit('/with_js')
  end

  it 'should be false if the page has the given title' do
    expect(@session).not_to have_no_title('with_js')
  end

  it 'should allow regexp matches' do
    expect(@session).not_to have_no_title(/w[a-z]{3}_js/)
    expect(@session).to have_no_title(/monkey/)
  end

  it 'should wait for title to disappear', requires: [:js] do
    Capybara.using_wait_time(5) do
      @session.click_link('Change title') # triggers title change after 400ms
      expect(@session).to have_no_title('with_js')
    end
  end

  it 'should be true if the page has not the given title' do
    expect(@session).to have_no_title('monkey')
    expect(@session.has_no_title?('monkey')).to be true
  end
end
