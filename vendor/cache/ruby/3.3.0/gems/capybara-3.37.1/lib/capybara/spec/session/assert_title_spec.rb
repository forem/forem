# frozen_string_literal: true

Capybara::SpecHelper.spec '#assert_title' do
  before do
    @session.visit('/with_js')
  end

  it "should not raise if the page's title contains the given string" do
    expect do
      @session.assert_title('js')
    end.not_to raise_error
  end

  it 'should not raise when given an empty string' do
    expect do
      @session.assert_title('')
    end.not_to raise_error
  end

  it 'should allow regexp matches' do
    expect do
      @session.assert_title(/w[a-z]{3}_js/)
    end.not_to raise_error

    expect do
      @session.assert_title(/w[a-z]{10}_js/)
    end.to raise_error(Capybara::ExpectationNotMet, 'expected "with_js" to match /w[a-z]{10}_js/')
  end

  it 'should wait for title', requires: [:js] do
    @session.click_link('Change title')
    expect do
      @session.assert_title('changed title', wait: 3)
    end.not_to raise_error
  end

  it "should raise error if the title doesn't contain the given string" do
    expect do
      @session.assert_title('monkey')
    end.to raise_error(Capybara::ExpectationNotMet, 'expected "with_js" to include "monkey"')
  end

  it 'should not normalize given title' do
    @session.visit('/with_js')
    expect { @session.assert_title('  with_js  ') }.to raise_error(Capybara::ExpectationNotMet)
  end

  it 'should match correctly normalized title' do
    uri = Addressable::URI.parse('/with_title')
    uri.query_values = { title: ' &nbsp; with space &nbsp;title   ' }
    @session.visit(uri.to_s)
    @session.assert_title('  with space  title')
    expect { @session.assert_title('with space title') }.to raise_error(Capybara::ExpectationNotMet)
  end

  it 'should not normalize given title in error message' do
    expect do
      @session.assert_title(2)
    end.to raise_error(Capybara::ExpectationNotMet, 'expected "with_js" to include "2"')
  end
end

Capybara::SpecHelper.spec '#assert_no_title' do
  before do
    @session.visit('/with_js')
  end

  it 'should raise error if the title contains the given string' do
    expect do
      @session.assert_no_title('with_j')
    end.to raise_error(Capybara::ExpectationNotMet, 'expected "with_js" not to include "with_j"')
  end

  it 'should allow regexp matches' do
    expect do
      @session.assert_no_title(/w[a-z]{3}_js/)
    end.to raise_error(Capybara::ExpectationNotMet, 'expected "with_js" not to match /w[a-z]{3}_js/')
    @session.assert_no_title(/monkey/)
  end

  it 'should wait for title to disappear', requires: [:js] do
    @session.click_link('Change title')
    expect do
      @session.assert_no_title('with_js', wait: 3)
    end.not_to raise_error
  end

  it "should not raise if the title doesn't contain the given string" do
    expect do
      @session.assert_no_title('monkey')
    end.not_to raise_error
  end
end
