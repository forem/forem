# frozen_string_literal: true

Capybara::SpecHelper.spec '#fill_in' do
  before do
    @session.visit('/form')
  end

  it 'should fill in a text field by id' do
    @session.fill_in('form_first_name', with: 'Harry')
    @session.click_button('awesome')
    expect(extract_results(@session)['first_name']).to eq('Harry')
  end

  it 'should fill in a text field by name' do
    @session.fill_in('form[last_name]', with: 'Green')
    @session.click_button('awesome')
    expect(extract_results(@session)['last_name']).to eq('Green')
  end

  it 'should fill in a text field by label without for' do
    @session.fill_in('First Name', with: 'Harry')
    @session.click_button('awesome')
    expect(extract_results(@session)['first_name']).to eq('Harry')
  end

  it 'should fill in a url field by label without for' do
    @session.fill_in('Html5 Url', with: 'http://www.avenueq.com')
    @session.click_button('html5_submit')
    expect(extract_results(@session)['html5_url']).to eq('http://www.avenueq.com')
  end

  it 'should fill in a textarea by id' do
    @session.fill_in('form_description', with: 'Texty text')
    @session.click_button('awesome')
    expect(extract_results(@session)['description']).to eq('Texty text')
  end

  it 'should fill in a textarea by label' do
    @session.fill_in('Description', with: 'Texty text')
    @session.click_button('awesome')
    expect(extract_results(@session)['description']).to eq('Texty text')
  end

  it 'should fill in a textarea by name' do
    @session.fill_in('form[description]', with: 'Texty text')
    @session.click_button('awesome')
    expect(extract_results(@session)['description']).to eq('Texty text')
  end

  it 'should fill in a textarea in a reasonable time by default' do
    textarea = @session.find(:fillable_field, 'form[description]')
    value = 'a' * 4000
    start = Time.now
    textarea.fill_in(with: value)
    expect(Time.now.to_f).to be_within(0.25).of start.to_f
    expect(textarea.value).to eq value
  end

  it 'should fill in a password field by id' do
    @session.fill_in('form_password', with: 'supasikrit')
    @session.click_button('awesome')
    expect(extract_results(@session)['password']).to eq('supasikrit')
  end

  context 'Date/Time' do
    it 'should fill in a date input' do
      date = Date.today
      @session.fill_in('form_date', with: date)
      @session.click_button('awesome')
      expect(Date.parse(extract_results(@session)['date'])).to eq date
    end

    it 'should fill in a time input' do
      time = Time.new(2018, 3, 9, 15, 26)
      @session.fill_in('form_time', with: time)
      @session.click_button('awesome')
      results = extract_results(@session)['time']
      expect(Time.parse(results).strftime('%r')).to eq time.strftime('%r')
    end

    it 'should fill in a datetime input' do
      dt = Time.new(2018, 3, 13, 9, 53)
      @session.fill_in('form_datetime', with: dt)
      @session.click_button('awesome')
      expect(Time.parse(extract_results(@session)['datetime'])).to eq dt
    end
  end

  it 'should handle HTML in a textarea' do
    @session.fill_in('form_description', with: 'is <strong>very</strong> secret!')
    @session.click_button('awesome')
    expect(extract_results(@session)['description']).to eq('is <strong>very</strong> secret!')
  end

  it 'should handle newlines in a textarea' do
    @session.fill_in('form_description', with: "\nSome text\n")
    @session.click_button('awesome')
    expect(extract_results(@session)['description']).to eq("\r\nSome text\r\n")
  end

  it 'should fill in a color field' do
    @session.fill_in('Html5 Color', with: '#112233')
    @session.click_button('html5_submit')
    expect(extract_results(@session)['html5_color']).to eq('#112233')
  end

  describe 'with input[type="range"]' do
    it 'should set the range slider correctly' do
      @session.fill_in('form_age', with: 51)
      @session.click_button('awesome')
      expect(extract_results(@session)['age'].to_f).to eq 51
    end

    it 'should set the range slider to valid values' do
      @session.fill_in('form_age', with: '37.6')
      @session.click_button('awesome')
      expect(extract_results(@session)['age'].to_f).to eq 37.5
    end

    it 'should respect the range slider limits' do
      @session.fill_in('form_age', with: '3')
      @session.click_button('awesome')
      expect(extract_results(@session)['age'].to_f).to eq 13
    end
  end

  it 'should fill in a field with a custom type' do
    @session.fill_in('Schmooo', with: 'Schmooo is the game')
    @session.click_button('awesome')
    expect(extract_results(@session)['schmooo']).to eq('Schmooo is the game')
  end

  it 'should fill in a field without a type' do
    @session.fill_in('Phone', with: '+1 555 7022')
    @session.click_button('awesome')
    expect(extract_results(@session)['phone']).to eq('+1 555 7022')
  end

  it 'should fill in a text field respecting its maxlength attribute' do
    @session.fill_in('Zipcode', with: '52071350')
    @session.click_button('awesome')
    expect(extract_results(@session)['zipcode']).to eq('52071')
  end

  it 'should fill in a password field by name' do
    @session.fill_in('form[password]', with: 'supasikrit')
    @session.click_button('awesome')
    expect(extract_results(@session)['password']).to eq('supasikrit')
  end

  it 'should fill in a password field by label' do
    @session.fill_in('Password', with: 'supasikrit')
    @session.click_button('awesome')
    expect(extract_results(@session)['password']).to eq('supasikrit')
  end

  it 'should fill in a password field by name' do
    @session.fill_in('form[password]', with: 'supasikrit')
    @session.click_button('awesome')
    expect(extract_results(@session)['password']).to eq('supasikrit')
  end

  it 'should fill in a field based on current value' do
    @session.fill_in(id: /form.*name/, currently_with: 'John', with: 'Thomas')
    @session.click_button('awesome')
    expect(extract_results(@session)['first_name']).to eq('Thomas')
  end

  it 'should fill in a field based on type' do
    @session.fill_in(type: 'schmooo', with: 'Schmooo for all')
    @session.click_button('awesome')
    expect(extract_results(@session)['schmooo']).to eq('Schmooo for all')
  end

  it 'should be able to fill in element called on when no locator passed' do
    field = @session.find(:fillable_field, 'form[password]')
    field.fill_in(with: 'supasikrit')
    @session.click_button('awesome')
    expect(extract_results(@session)['password']).to eq('supasikrit')
  end

  it "should throw an exception if a hash containing 'with' is not provided" do
    expect { @session.fill_in 'Name' }.to raise_error(ArgumentError, /with/)
  end

  it 'should wait for asynchronous load', requires: [:js] do
    Capybara.default_max_wait_time = 2
    @session.visit('/with_js')
    @session.click_link('Click me')
    @session.fill_in('new_field', with: 'Testing...')
  end

  it 'casts to string' do
    @session.fill_in(:form_first_name, with: :Harry)
    @session.click_button('awesome')
    expect(extract_results(@session)['first_name']).to eq('Harry')
  end

  it 'casts to string if field has maxlength' do
    @session.fill_in(:form_zipcode, with: 1234567)
    @session.click_button('awesome')
    expect(extract_results(@session)['zipcode']).to eq('12345')
  end

  it 'fills in a field if default_set_options is nil' do
    Capybara.default_set_options = nil
    @session.fill_in(:form_first_name, with: 'Thomas')
    @session.click_button('awesome')
    expect(extract_results(@session)['first_name']).to eq('Thomas')
  end

  context 'on a pre-populated textfield with a reformatting onchange', requires: [:js] do
    it 'should only trigger onchange once' do
      @session.visit('/with_js')
      # Click somewhere on the page to ensure focus is acquired. Without this FF won't generate change events for some reason???
      @session.find(:css, 'h1', text: 'FooBar').click
      @session.fill_in('with_change_event', with: 'some value')
      # click outside the field to trigger the change event
      @session.find(:css, 'h1', text: 'FooBar').click
      expect(@session.find(:css, '.change_event_triggered', match: :one)).to have_text 'some value'
    end

    it 'should trigger change when clearing field' do
      @session.visit('/with_js')
      @session.fill_in('with_change_event', with: '')
      # click outside the field to trigger the change event
      @session.find(:css, 'h1', text: 'FooBar').click
      expect(@session).to have_selector(:css, '.change_event_triggered', match: :one)
    end
  end

  context 'with ignore_hidden_fields' do
    before { Capybara.ignore_hidden_elements = true }

    after  { Capybara.ignore_hidden_elements = false }

    it 'should not find a hidden field' do
      msg = /Unable to find visible field "Super Secret"/
      expect do
        @session.fill_in('Super Secret', with: '777')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context "with a locator that doesn't exist" do
    it 'should raise an error' do
      msg = /Unable to find field "does not exist"/
      expect do
        @session.fill_in('does not exist', with: 'Blah blah')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'on a disabled field' do
    it 'should raise an error' do
      expect do
        @session.fill_in('Disabled Text Field', with: 'Blah blah')
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with :exact option' do
    it 'should accept partial matches when false' do
      @session.fill_in('Explanation', with: 'Dude', exact: false)
      @session.click_button('awesome')
      expect(extract_results(@session)['name_explanation']).to eq('Dude')
    end

    it 'should not accept partial matches when true' do
      expect do
        @session.fill_in('Explanation', with: 'Dude', exact: true)
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  it 'should return the element filled in' do
    el = @session.find(:fillable_field, 'form_first_name')
    expect(@session.fill_in('form_first_name', with: 'Harry')).to eq el
  end

  it 'should warn if passed what looks like a CSS id selector' do
    expect do
      @session.fill_in('#form_first_name', with: 'Harry')
    end.to raise_error(/you may be passing a CSS selector or XPath expression rather than a locator/)
  end
end
