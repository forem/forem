# frozen_string_literal: true

Capybara::SpecHelper.spec '#find_field' do
  before do
    @session.visit('/form')
  end

  it 'should find any field' do
    Capybara.test_id = 'data-test-id'
    expect(@session.find_field('Dog').value).to eq('dog')
    expect(@session.find_field('form_description').value).to eq('Descriptive text goes here')
    expect(@session.find_field('Region')[:name]).to eq('form[region]')
    expect(@session.find_field('With Asterisk*')).to be_truthy
    expect(@session.find_field('my_test_id')).to be_truthy
  end

  context 'aria_label attribute with Capybara.enable_aria_label' do
    it 'should find when true' do
      Capybara.enable_aria_label = true
      expect(@session.find_field('Unlabelled Input')[:name]).to eq('form[which_form]')
      # expect(@session.find_field('Emergency Number')[:id]).to eq('html5_tel')
    end

    it 'should not find when false' do
      Capybara.enable_aria_label = false
      expect { @session.find_field('Unlabelled Input') }.to raise_error(Capybara::ElementNotFound)
      # expect { @session.find_field('Emergency Number') }.to raise_error(Capybara::ElementNotFound)
    end
  end

  it 'casts to string' do
    expect(@session.find_field(:Dog).value).to eq('dog')
  end

  it "should raise error if the field doesn't exist" do
    expect do
      @session.find_field('Does not exist')
    end.to raise_error(Capybara::ElementNotFound)
  end

  it 'should raise error if filter option is invalid' do
    expect do
      @session.find_field('Dog', disabled: nil)
    end.to raise_error ArgumentError, 'Invalid value nil passed to NodeFilter disabled'
  end

  context 'with :exact option' do
    it 'should accept partial matches when false' do
      expect(@session.find_field('Explanation', exact: false)[:name]).to eq('form[name_explanation]')
    end

    it 'should not accept partial matches when true' do
      expect do
        @session.find_field('Explanation', exact: true)
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'with :disabled option' do
    it 'should find disabled fields when true' do
      expect(@session.find_field('Disabled Checkbox', disabled: true)[:name]).to eq('form[disabled_checkbox]')
      expect(@session.find_field('form_disabled_fieldset_child', disabled: true)[:name]).to eq('form[disabled_fieldset_child]')
      expect(@session.find_field('form_disabled_fieldset_descendant', disabled: true)[:name]).to eq('form[disabled_fieldset_descendant]')
    end

    it 'should not find disabled fields when false' do
      expect do
        @session.find_field('Disabled Checkbox', disabled: false)
      end.to raise_error(Capybara::ElementNotFound)
    end

    it 'should not find disabled fields by default' do
      expect do
        @session.find_field('Disabled Checkbox')
      end.to raise_error(Capybara::ElementNotFound)
    end

    it 'should find disabled fields when :all' do
      expect(@session.find_field('Disabled Checkbox', disabled: :all)[:name]).to eq('form[disabled_checkbox]')
    end

    it 'should find enabled fields when :all' do
      expect(@session.find_field('Dog', disabled: :all).value).to eq('dog')
    end
  end

  context 'with :readonly option' do
    it 'should find readonly fields when true' do
      expect(@session.find_field('form[readonly_test]', readonly: true)[:id]).to eq 'readonly'
    end

    it 'should not find readonly fields when false' do
      expect(@session.find_field('form[readonly_test]', readonly: false)[:id]).to eq 'not_readonly'
    end

    it 'should ignore readonly by default' do
      expect do
        @session.find_field('form[readonly_test]')
      end.to raise_error(Capybara::Ambiguous, /found 2 elements/)
    end
  end

  context 'with no locator' do
    it 'should use options to find the field' do
      expect(@session.find_field(type: 'checkbox', with: 'dog')['id']).to eq 'form_pets_dog'
    end
  end

  it 'should accept an optional filter block' do
    # this would be better done with the :with option but this is just a test
    expect(@session.find_field('form[pets][]') { |node| node.value == 'dog' }[:id]).to eq 'form_pets_dog'
  end
end
