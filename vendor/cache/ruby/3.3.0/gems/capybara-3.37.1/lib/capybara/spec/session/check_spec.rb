# frozen_string_literal: true

Capybara::SpecHelper.spec '#check' do
  before do
    @session.visit('/form')
  end

  describe "'checked' attribute" do
    it 'should be true if checked' do
      @session.check('Terms of Use')
      expect(@session.find(:xpath, "//input[@id='form_terms_of_use']")['checked']).to be_truthy
    end

    it 'should be false if unchecked' do
      expect(@session.find(:xpath, "//input[@id='form_terms_of_use']")['checked']).to be_falsey
    end
  end

  it 'should trigger associated events', requires: [:js] do
    @session.visit('/with_js')
    @session.check('checkbox_with_event')
    expect(@session).to have_css('#checkbox_event_triggered')
  end

  describe 'checking' do
    it 'should not change an already checked checkbox' do
      expect(@session.find(:xpath, "//input[@id='form_pets_dog']")).to be_checked
      @session.check('form_pets_dog')
      expect(@session.find(:xpath, "//input[@id='form_pets_dog']")).to be_checked
    end

    it 'should check an unchecked checkbox' do
      expect(@session.find(:xpath, "//input[@id='form_pets_cat']")).not_to be_checked
      @session.check('form_pets_cat')
      expect(@session.find(:xpath, "//input[@id='form_pets_cat']")).to be_checked
    end
  end

  describe 'unchecking' do
    it 'should not change an already unchecked checkbox' do
      expect(@session.find(:xpath, "//input[@id='form_pets_cat']")).not_to be_checked
      @session.uncheck('form_pets_cat')
      expect(@session.find(:xpath, "//input[@id='form_pets_cat']")).not_to be_checked
    end

    it 'should uncheck a checked checkbox' do
      expect(@session.find(:xpath, "//input[@id='form_pets_dog']")).to be_checked
      @session.uncheck('form_pets_dog')
      expect(@session.find(:xpath, "//input[@id='form_pets_dog']")).not_to be_checked
    end
  end

  it 'should check a checkbox by id' do
    @session.check('form_pets_cat')
    @session.click_button('awesome')
    expect(extract_results(@session)['pets']).to include('dog', 'cat', 'hamster')
  end

  it 'should check a checkbox by label' do
    @session.check('Cat')
    @session.click_button('awesome')
    expect(extract_results(@session)['pets']).to include('dog', 'cat', 'hamster')
  end

  it 'should work without a locator string' do
    @session.check(id: 'form_pets_cat')
    @session.click_button('awesome')
    expect(extract_results(@session)['pets']).to include('dog', 'cat', 'hamster')
  end

  it 'should be able to check itself if no locator specified' do
    cb = @session.find(:id, 'form_pets_cat')
    cb.check
    @session.click_button('awesome')
    expect(extract_results(@session)['pets']).to include('dog', 'cat', 'hamster')
  end

  it 'casts to string' do
    @session.check(:form_pets_cat)
    @session.click_button('awesome')
    expect(extract_results(@session)['pets']).to include('dog', 'cat', 'hamster')
  end

  context "with a locator that doesn't exist" do
    it 'should raise an error' do
      msg = /Unable to find checkbox "does not exist"/
      expect do
        @session.check('does not exist')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'with a disabled checkbox' do
    it 'should raise an error' do
      msg = 'Unable to find visible checkbox "Disabled Checkbox" that is not disabled'
      expect do
        @session.check('Disabled Checkbox')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'with :exact option' do
    it 'should accept partial matches when false' do
      @session.check('Ham', exact: false)
      @session.click_button('awesome')
      expect(extract_results(@session)['pets']).to include('hamster')
    end

    it 'should not accept partial matches when true' do
      expect do
        @session.check('Ham', exact: true)
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with `option` option' do
    it 'can check boxes by their value' do
      @session.check('form[pets][]', option: 'cat')
      @session.click_button('awesome')
      expect(extract_results(@session)['pets']).to include('cat')
    end

    it 'should alias `with`' do
      @session.check('form[pets][]', with: 'cat')
      @session.click_button('awesome')
      expect(extract_results(@session)['pets']).to include('cat')
    end

    it 'should raise an error if option not found' do
      expect do
        @session.check('form[pets][]', option: 'elephant')
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'when checkbox hidden' do
    context 'with Capybara.automatic_label_click == true' do
      around do |spec|
        old_click_label, Capybara.automatic_label_click = Capybara.automatic_label_click, true
        spec.run
        Capybara.automatic_label_click = old_click_label
      end

      it 'should check via clicking the label with :for attribute if possible' do
        expect(@session.find(:checkbox, 'form_cars_tesla', unchecked: true, visible: :hidden)).to be_truthy
        @session.check('form_cars_tesla')
        @session.click_button('awesome')
        expect(extract_results(@session)['cars']).to include('tesla')
      end

      it 'should check via clicking the wrapping label if possible' do
        expect(@session.find(:checkbox, 'form_cars_mclaren', unchecked: true, visible: :hidden)).to be_truthy
        @session.check('form_cars_mclaren')
        @session.click_button('awesome')
        expect(extract_results(@session)['cars']).to include('mclaren')
      end

      it 'should check via clicking the label with :for attribute if locator nil' do
        cb = @session.find(:checkbox, 'form_cars_tesla', unchecked: true, visible: :hidden)
        cb.check
        @session.click_button('awesome')
        expect(extract_results(@session)['cars']).to include('tesla')
      end

      it 'should check self via clicking the wrapping label if locator nil' do
        cb = @session.find(:checkbox, 'form_cars_mclaren', unchecked: true, visible: :hidden)
        cb.check
        @session.click_button('awesome')
        expect(extract_results(@session)['cars']).to include('mclaren')
      end

      it 'should not click the label if unneeded' do
        expect(@session.find(:checkbox, 'form_cars_jaguar', checked: true, visible: :hidden)).to be_truthy
        @session.check('form_cars_jaguar')
        @session.click_button('awesome')
        expect(extract_results(@session)['cars']).to include('jaguar')
      end

      it 'should raise original error when no label available' do
        expect { @session.check('form_cars_ariel') }.to raise_error(Capybara::ElementNotFound, /Unable to find visible checkbox "form_cars_ariel"/)
      end

      it 'should raise error if not allowed to click label' do
        expect { @session.check('form_cars_mclaren', allow_label_click: false) }.to raise_error(Capybara::ElementNotFound, /Unable to find visible checkbox "form_cars_mclaren"/)
      end
    end

    context 'with Capybara.automatic_label_click == false' do
      around do |spec|
        old_label_click, Capybara.automatic_label_click = Capybara.automatic_label_click, false
        spec.run
        Capybara.automatic_label_click = old_label_click
      end

      it 'should raise error if checkbox not visible' do
        expect { @session.check('form_cars_mclaren') }.to raise_error(Capybara::ElementNotFound, /Unable to find visible checkbox "form_cars_mclaren"/)
      end

      it 'should include node filter in error if verified' do
        expect { @session.check('form_cars_maserati') }.to raise_error(Capybara::ElementNotFound, 'Unable to find visible checkbox "form_cars_maserati" that is not disabled')
      end

      context 'with allow_label_click == true' do
        it 'should check via the label if input is hidden' do
          expect(@session.find(:checkbox, 'form_cars_tesla', unchecked: true, visible: :hidden)).to be_truthy
          @session.check('form_cars_tesla', allow_label_click: true)
          @session.click_button('awesome')
          expect(extract_results(@session)['cars']).to include('tesla')
        end

        it 'should not wait the full time if label can be clicked' do
          expect(@session.find(:checkbox, 'form_cars_tesla', unchecked: true, visible: :hidden)).to be_truthy
          start_time = Time.now
          @session.check('form_cars_tesla', allow_label_click: true, wait: 10)
          end_time = Time.now
          expect(end_time - start_time).to be < 10
        end

        it 'should check via the label if input is moved off the left edge of the page' do
          expect(@session.find(:checkbox, 'form_cars_pagani', unchecked: true, visible: :all)).to be_truthy
          @session.check('form_cars_pagani', allow_label_click: true)
          @session.click_button('awesome')
          expect(extract_results(@session)['cars']).to include('pagani')
        end

        it 'should check via the label if input is visible but blocked by another element' do
          expect(@session.find(:checkbox, 'form_cars_bugatti', unchecked: true, visible: :all)).to be_truthy
          @session.check('form_cars_bugatti', allow_label_click: true)
          @session.click_button('awesome')
          expect(extract_results(@session)['cars']).to include('bugatti')
        end

        it 'should check via label if multiple labels' do
          expect(@session).to have_field('multi_label_checkbox', checked: false, visible: :hidden)
          @session.check('Label to click', allow_label_click: true)
          expect(@session).to have_field('multi_label_checkbox', checked: true, visible: :hidden)
        end
      end

      context 'with allow_label_click options', requires: [:js] do
        it 'should allow offsets to click location on label' do
          expect(@session.find(:checkbox, 'form_cars_lotus', unchecked: true, visible: :hidden)).to be_truthy
          @session.check('form_cars_lotus', allow_label_click: { x: 90, y: 10 })
          @session.click_button('awesome')
          expect(extract_results(@session)['cars']).to include('lotus')
        end
      end
    end
  end
end
