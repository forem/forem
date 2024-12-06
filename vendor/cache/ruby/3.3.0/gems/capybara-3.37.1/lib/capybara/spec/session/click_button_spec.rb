# frozen_string_literal: true

Capybara::SpecHelper.spec '#click_button' do
  before do
    @session.visit('/form')
  end

  it 'should wait for asynchronous load', requires: [:js] do
    @session.visit('/with_js')
    @session.using_wait_time(1.5) do
      @session.click_link('Click me')
      @session.click_button('New Here')
    end
  end

  it 'casts to string' do
    @session.click_button(:'Relative Action')
    expect(extract_results(@session)['relative']).to eq('Relative Action')
    expect(@session.current_path).to eq('/relative')
  end

  context 'with multiple values with the same name' do
    it 'should use the latest given value' do
      @session.check('Terms of Use')
      @session.click_button('awesome')
      expect(extract_results(@session)['terms_of_use']).to eq('1')
    end
  end

  context 'with a form that has a relative url as an action' do
    it 'should post to the correct url' do
      @session.click_button('Relative Action')
      expect(extract_results(@session)['relative']).to eq('Relative Action')
      expect(@session.current_path).to eq('/relative')
    end
  end

  context 'with a form that has no action specified' do
    it 'should post to the correct url' do
      @session.click_button('No Action')
      expect(extract_results(@session)['no_action']).to eq('No Action')
      expect(@session.current_path).to eq('/form')
    end
  end

  context 'with value given on a submit button' do
    context 'on a form with HTML5 fields' do
      let(:results) { extract_results(@session) }

      before do
        @session.click_button('html5_submit')
      end

      it 'should serialise and submit search fields' do
        expect(results['html5_search']).to eq('what are you looking for')
      end

      it 'should serialise and submit email fields' do
        expect(results['html5_email']).to eq('person@email.com')
      end

      it 'should serialise and submit url fields' do
        expect(results['html5_url']).to eq('http://www.example.com')
      end

      it 'should serialise and submit tel fields' do
        expect(results['html5_tel']).to eq('911')
      end

      it 'should serialise and submit color fields' do
        expect(results['html5_color'].upcase).to eq('#FFFFFF')
      end
    end

    context 'on an HTML4 form' do
      let(:results) { extract_results(@session) }

      before do
        @session.click_button('awesome')
      end

      it 'should serialize and submit text fields' do
        expect(results['first_name']).to eq('John')
      end

      it 'should escape fields when submitting' do
        expect(results['phone']).to eq('+1 555 7021')
      end

      it 'should serialize and submit password fields' do
        expect(results['password']).to eq('seeekrit')
      end

      it 'should serialize and submit hidden fields' do
        expect(results['token']).to eq('12345')
      end

      it 'should not serialize fields from other forms' do
        expect(results['middle_name']).to be_nil
      end

      it 'should submit the button that was clicked, but not other buttons' do
        expect(results['awesome']).to eq('awesome')
        expect(results['crappy']).to be_nil
      end

      it 'should serialize radio buttons' do
        expect(results['gender']).to eq('female')
      end

      it "should default radio value to 'on' if none specified" do
        expect(results['valueless_radio']).to eq('on')
      end

      it 'should serialize check boxes' do
        expect(results['pets']).to include('dog', 'hamster')
        expect(results['pets']).not_to include('cat')
      end

      it "should default checkbox value to 'on' if none specififed" do
        expect(results['valueless_checkbox']).to eq('on')
      end

      it 'should serialize text areas' do
        expect(results['description']).to eq('Descriptive text goes here')
      end

      it 'should serialize select tag with values' do
        expect(results['locale']).to eq('en')
      end

      it 'should serialize select tag without values' do
        expect(results['region']).to eq('Norway')
      end

      it 'should serialize first option for select tag with no selection' do
        expect(results['city']).to eq('London')
      end

      it 'should not serialize a select tag without options' do
        expect(results['tendency']).to be_nil
      end

      it 'should convert lf to cr/lf in submitted textareas' do
        expect(results['newline']).to eq("\r\nNew line after and before textarea tag\r\n")
      end

      it 'should not submit disabled fields' do
        expect(results['disabled_text_field']).to be_nil
        expect(results['disabled_textarea']).to be_nil
        expect(results['disabled_checkbox']).to be_nil
        expect(results['disabled_radio']).to be_nil
        expect(results['disabled_select']).to be_nil
        expect(results['disabled_file']).to be_nil
      end
    end
  end

  context 'input type=submit button' do
    it 'should submit by button id' do
      @session.click_button('awe123')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by specific button id' do
      @session.click_button(id: 'awe123')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by button title' do
      @session.click_button('What an Awesome Button')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by partial title', :exact_false do
      @session.click_button('What an Awesome')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by button name' do
      @session.click_button('form[awesome]')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by specific button name' do
      @session.click_button(name: 'form[awesome]')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit by specific button name regex' do
      @session.click_button(name: /form\[awes.*\]/)
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'when Capybara.enable_aria_role = true' do
    it 'should click on a button role', requires: [:js] do
      Capybara.enable_aria_role = true
      @session.using_wait_time(1.5) do
        @session.visit('/with_js')
        @session.click_button('ARIA button')
        expect(@session).to have_button('ARIA button has been clicked')
      end
    end
  end

  context 'with fields associated with the form using the form attribute', requires: [:form_attribute] do
    let(:results) { extract_results(@session) }

    before do
      @session.click_button('submit_form1')
    end

    it 'should serialize and submit text fields' do
      expect(results['outside_input']).to eq('outside_input')
    end

    it 'should serialize text areas' do
      expect(results['outside_textarea']).to eq('Some text here')
    end

    it 'should serialize select tags' do
      expect(results['outside_select']).to eq('Ruby')
    end

    it 'should not serliaze fields associated with a different form' do
      expect(results['for_form2']).to be_nil
    end
  end

  context 'with submit button outside the form defined by <button> tag', requires: [:form_attribute] do
    let(:results) { extract_results(@session) }

    before do
      @session.click_button('outside_button')
    end

    it 'should submit the associated form' do
      expect(results['which_form']).to eq('form2')
    end

    it 'should submit the button that was clicked, but not other buttons' do
      expect(results['outside_button']).to eq('outside_button')
      expect(results['unused']).to be_nil
    end
  end

  context "with submit button outside the form defined by <input type='submit'> tag", requires: [:form_attribute] do
    let(:results) { extract_results(@session) }

    before do
      @session.click_button('outside_submit')
    end

    it 'should submit the associated form' do
      expect(results['which_form']).to eq('form1')
    end

    it 'should submit the button that was clicked, but not other buttons' do
      expect(results['outside_submit']).to eq('outside_submit')
      expect(results['submit_form1']).to be_nil
    end
  end

  context 'with submit button for form1 located within form2', requires: [:form_attribute] do
    it 'should submit the form associated with the button' do
      @session.click_button('other_form_button')
      expect(extract_results(@session)['which_form']).to eq('form1')
    end
  end

  context 'with submit button not associated with any form' do
    it 'should not error when clicked' do
      expect { @session.click_button('no_form_button') }.not_to raise_error
    end
  end

  context 'with alt given on an image button' do
    it 'should submit the associated form' do
      @session.click_button('oh hai thar')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('hai')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with value given on an image button' do
    it 'should submit the associated form' do
      @session.click_button('okay')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('kay')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with id given on an image button' do
    it 'should submit the associated form' do
      @session.click_button('okay556')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with title given on an image button' do
    it 'should submit the associated form' do
      @session.click_button('Okay 556 Image')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('Okay 556')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with text given on a button defined by <button> tag' do
    it 'should submit the associated form' do
      @session.click_button('Click me!')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('Click')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with id given on a button defined by <button> tag' do
    it 'should submit the associated form' do
      @session.click_button('click_me_123')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should serialize and send GET forms' do
      @session.visit('/form')
      @session.click_button('med')
      results = extract_results(@session)
      expect(results['middle_name']).to eq('Darren')
      expect(results['foo']).to be_nil
    end
  end

  context 'with name given on a button defined by <button> tag' do
    it 'should submit the associated form when name is locator' do
      @session.click_button('form[no_value]')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should submit the associated form when name is specific' do
      @session.click_button(name: 'form[no_value]')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with value given on a button defined by <button> tag' do
    it 'should submit the associated form' do
      @session.click_button('click_me')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('ck_me')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with title given on a button defined by <button> tag' do
    it 'should submit the associated form' do
      @session.click_button('Click Title button')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('Click Title')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context 'with descendant image alt given on a button defined by <button> tag' do
    it 'should submit the associated form' do
      @session.click_button('A horse eating hay')
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should work with partial matches', :exact_false do
      @session.click_button('se eating h')
      expect(extract_results(@session)['first_name']).to eq('John')
    end
  end

  context "with a locator that doesn't exist" do
    it 'should raise an error' do
      msg = /Unable to find button "does not exist"/
      expect do
        @session.click_button('does not exist')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'with formaction attribute on button' do
    it 'should submit to the formaction attribute' do
      @session.click_button('Formaction button')
      results = extract_results(@session)
      expect(@session.current_path).to eq '/form'
      expect(results['which_form']).to eq 'formaction form'
    end
  end

  context 'with formmethod attribute on button' do
    it 'should submit to the formethod attribute' do
      @session.click_button('Formmethod button')
      results = extract_results(@session)
      expect(@session.current_path).to eq '/form/get'
      expect(results['which_form']).to eq 'formaction form'
    end
  end

  it 'should serialize and send valueless buttons that were clicked' do
    @session.click_button('No Value!')
    results = extract_results(@session)
    expect(results['no_value']).not_to be_nil
  end

  it 'should send button in document order' do
    @session.click_button('outside_button')
    results = extract_results(@session)
    expect(results.keys).to eq %w[for_form2 outside_button which_form post_count]
  end

  it 'should not send image buttons that were not clicked' do
    @session.click_button('Click me!')
    results = extract_results(@session)
    expect(results['okay']).to be_nil
  end

  it 'should serialize and send GET forms' do
    @session.visit('/form')
    @session.click_button('med')
    results = extract_results(@session)
    expect(results['middle_name']).to eq('Darren')
    expect(results['foo']).to be_nil
  end

  it 'should follow redirects' do
    @session.click_button('Go FAR')
    expect(@session).to have_content('You landed')
    expect(@session.current_url).to match(%r{/landed$})
  end

  it 'should follow temporary redirects that maintain method' do
    @session.click_button('Go 307')
    expect(@session).to have_content('You post landed: TWTW')
  end

  it 'should follow permanent redirects that maintain method' do
    @session.click_button('Go 308')
    expect(@session).to have_content('You post landed: TWTW')
  end

  it 'should post pack to the same URL when no action given' do
    @session.visit('/postback')
    @session.click_button('With no action')
    expect(@session).to have_content('Postback')
  end

  it 'should post pack to the same URL when blank action given' do
    @session.visit('/postback')
    @session.click_button('With blank action')
    expect(@session).to have_content('Postback')
  end

  it 'ignores disabled buttons' do
    expect do
      @session.click_button('Disabled button')
    end.to raise_error(Capybara::ElementNotFound)
  end

  it 'should encode complex field names, like array[][value]' do
    @session.visit('/form')
    @session.fill_in('address1_city', with: 'Paris')
    @session.fill_in('address1_street', with: 'CDG')

    @session.fill_in('address2_city', with: 'Mikolaiv')
    @session.fill_in('address2_street', with: 'PGS')

    @session.click_button 'awesome'

    addresses = extract_results(@session)['addresses']
    expect(addresses.size).to eq(2)

    expect(addresses[0]['street']).to eq('CDG')
    expect(addresses[0]['city']).to eq('Paris')
    expect(addresses[0]['country']).to eq('France')

    expect(addresses[1]['street']).to eq('PGS')
    expect(addresses[1]['city']).to eq('Mikolaiv')
    expect(addresses[1]['country']).to eq('Ukraine')
  end

  context 'with :exact option' do
    it 'should accept partial matches when false' do
      @session.click_button('What an Awesome', exact: false)
      expect(extract_results(@session)['first_name']).to eq('John')
    end

    it 'should not accept partial matches when true' do
      expect do
        @session.click_button('What an Awesome', exact: true)
      end.to raise_error(Capybara::ElementNotFound)
    end
  end
end
