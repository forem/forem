# frozen_string_literal: true

require 'spec_helper'
require 'capybara/minitest'
require 'capybara/minitest/spec'

class MinitestSpecTest < Minitest::Spec
  include ::Capybara::DSL
  include ::Capybara::Minitest::Assertions

  before do
    visit('/form')
  end

  after do
    Capybara.reset_sessions!
  end

  it 'supports text expectations' do
    _(page).must_have_text('Form', minimum: 1)
    _(page).wont_have_text('Not a form')
    form = find(:css, 'form', text: 'Title')
    _(form).must_have_text('Customer Email')
    _(form).wont_have_text('Some other email')
  end

  it 'supports current_path expectations' do
    _(page).must_have_current_path('/form')
    _(page).wont_have_current_path('/form2')
  end

  it 'supports title expectations' do
    visit('/with_title')
    _(page).must_have_title('Test Title')
    _(page).wont_have_title('Not the title')
  end

  it 'supports xpath expectations' do
    _(page).must_have_xpath('.//input[@id="customer_email"]')
    _(page).wont_have_xpath('.//select[@id="not_form_title"]')
    _(page).wont_have_xpath('.//input[@id="customer_email"]') { |el| el[:id] == 'not_customer_email' }
    select = find(:select, 'form_title')
    _(select).must_have_xpath('.//option[@class="title"]')
    _(select).must_have_xpath('.//option', count: 1) { |option| option[:class] != 'title' && !option.disabled? }
    _(select).wont_have_xpath('.//input[@id="customer_email"]')
  end

  it 'support css expectations' do
    _(page).must_have_css('input#customer_email')
    _(page).wont_have_css('select#not_form_title')
    el = find(:select, 'form_title')
    _(el).must_have_css('option.title')
    _(el).wont_have_css('input#customer_email')
  end

  it 'supports link expectations' do
    visit('/with_html')
    _(page).must_have_link('A link')
    _(page).wont_have_link('Not on page')
  end

  it 'supports button expectations' do
    _(page).must_have_button('fresh_btn')
    _(page).wont_have_button('not_btn')
  end

  it 'supports field expectations' do
    _(page).must_have_field('customer_email')
    _(page).wont_have_field('not_on_the_form')
  end

  it 'supports select expectations' do
    _(page).must_have_select('form_title')
    _(page).wont_have_select('not_form_title')
  end

  it 'supports checked_field expectations' do
    _(page).must_have_checked_field('form_pets_dog')
    _(page).wont_have_checked_field('form_pets_cat')
  end

  it 'supports unchecked_field expectations' do
    _(page).must_have_unchecked_field('form_pets_cat')
    _(page).wont_have_unchecked_field('form_pets_dog')
  end

  it 'supports table expectations' do
    visit('/tables')
    _(page).must_have_table('agent_table')
    _(page).wont_have_table('not_on_form')
  end

  it 'supports all_of_selectors expectations' do
    _(page).must_have_all_of_selectors(:css, 'select#form_other_title', 'input#form_last_name')
  end

  it 'supports none_of_selectors expectations' do
    _(page).must_have_none_of_selectors(:css, 'input#not_on_page', 'input#also_not_on_page')
  end

  it 'supports any_of_selectors expectations' do
    _(page).must_have_any_of_selectors(:css, 'select#form_other_title', 'input#not_on_page')
  end

  it 'supports match_selector expectations' do
    _(find(:field, 'customer_email')).must_match_selector(:field, 'customer_email')
    _(find(:select, 'form_title')).wont_match_selector(:field, 'customer_email')
  end

  it 'supports match_css expectations' do
    _(find(:select, 'form_title')).must_match_css('select#form_title')
    _(find(:select, 'form_title')).wont_match_css('select#form_other_title')
  end

  it 'supports match_xpath expectations' do
    _(find(:select, 'form_title')).must_match_xpath('.//select[@id="form_title"]')
    _(find(:select, 'form_title')).wont_match_xpath('.//select[@id="not_on_page"]')
  end

  it 'handles failures' do
    _(page).must_have_select('non_existing_form_title')
  end

  it 'supports style expectations' do
    skip "Rack test doesn't support style" if Capybara.current_driver == :rack_test
    visit('/with_html')
    _(find(:css, '#second')).must_have_style('display' => 'inline') # deprecated
    _(find(:css, '#second')).must_match_style('display' => 'inline')
  end

  it 'supports ancestor expectations' do
    option = find(:option, 'Finnish')
    _(option).must_have_ancestor(:css, '#form_locale')
  end

  it 'supports sibling expectations' do
    option = find(:css, '#form_title').find(:option, 'Mrs')
    _(option).must_have_sibling(:option, 'Mr')
  end
end

RSpec.describe 'capybara/minitest/spec' do
  before do
    Capybara.current_driver = :rack_test
    Capybara.app = TestApp
  end

  after do
    Capybara.use_default_driver
  end

  it 'should support minitest spec' do
    output = StringIO.new
    reporter = Minitest::SummaryReporter.new(output)
    reporter.start
    MinitestSpecTest.run reporter, {}
    reporter.report
    expect(output.string).to include('22 runs, 44 assertions, 1 failures, 0 errors, 1 skips')
    # Make sure error messages are displayed
    expect(output.string).to match(/expected to find select box "non_existing_form_title" .*but there were no matches/)
  end
end
