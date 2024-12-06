# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_select?' do
  before { @session.visit('/form') }

  it 'should be true if the field is on the page' do
    expect(@session).to have_select('Locale')
    expect(@session).to have_select('form_region')
    expect(@session).to have_select('Languages')
    expect(@session).to have_select(:Languages)
  end

  it 'should be false if the field is not on the page' do
    expect(@session).not_to have_select('Monkey')
  end

  context 'with selected value' do
    it 'should be true if a field with the given value is on the page' do
      expect(@session).to have_select('form_locale', selected: 'English')
      expect(@session).to have_select('Region', selected: 'Norway')
      expect(@session).to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end

    it 'should be false if the given field is not on the page' do
      expect(@session).not_to have_select('Locale', selected: 'Swedish')
      expect(@session).not_to have_select('Does not exist', selected: 'John')
      expect(@session).not_to have_select('City', selected: 'Not there')
      expect(@session).not_to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns', 'Nonexistent'
      ])
      expect(@session).not_to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Boxers', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
      expect(@session).not_to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons"
      ])
    end

    it 'should be true after the given value is selected' do
      @session.select('Swedish', from: 'Locale')
      expect(@session).to have_select('Locale', selected: 'Swedish')
    end

    it 'should be false after a different value is selected' do
      @session.select('Swedish', from: 'Locale')
      expect(@session).not_to have_select('Locale', selected: 'English')
    end

    it 'should be true after the given values are selected' do
      @session.select('Boxers', from: 'Underwear')
      expect(@session).to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Boxers', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end

    it 'should be false after one of the values is unselected' do
      @session.unselect('Briefs', from: 'Underwear')
      expect(@session).not_to have_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end

    it "should be true even when the selected option invisible, regardless of the select's visibility" do
      expect(@session).to have_select('Icecream', visible: :hidden, selected: 'Chocolate')
      expect(@session).to have_select('Sorbet', selected: 'Vanilla')
    end
  end

  context 'with partial select' do
    it 'should be true if a field with the given partial values is on the page' do
      expect(@session).to have_select('Underwear', with_selected: %w[Boxerbriefs Briefs])
    end

    it 'should be false if a field with the given partial values is not on the page' do
      expect(@session).not_to have_select('Underwear', with_selected: %w[Boxerbriefs Boxers])
    end

    it 'should be true after the given partial value is selected' do
      @session.select('Boxers', from: 'Underwear')
      expect(@session).to have_select('Underwear', with_selected: %w[Boxerbriefs Boxers])
    end

    it 'should be false after one of the given partial values is unselected' do
      @session.unselect('Briefs', from: 'Underwear')
      expect(@session).not_to have_select('Underwear', with_selected: %w[Boxerbriefs Briefs])
    end

    it "should be true even when the selected values are invisible, regardless of the select's visibility" do
      expect(@session).to have_select('Dessert', visible: :hidden, with_options: %w[Pudding Tiramisu])
      expect(@session).to have_select('Cake', with_selected: ['Chocolate Cake', 'Sponge Cake'])
    end

    it 'should support non array partial values' do
      expect(@session).to have_select('Underwear', with_selected: 'Briefs')
      expect(@session).not_to have_select('Underwear', with_selected: 'Boxers')
    end
  end

  context 'with exact options' do
    it 'should be true if a field with the given options is on the page' do
      expect(@session).to have_select('Region', options: %w[Norway Sweden Finland])
      expect(@session).to have_select('Tendency', options: [])
    end

    it 'should be false if the given field is not on the page' do
      expect(@session).not_to have_select('Locale', options: ['Swedish'])
      expect(@session).not_to have_select('Does not exist', options: ['John'])
      expect(@session).not_to have_select('City', options: ['London', 'Made up city'])
      expect(@session).not_to have_select('Region', options: %w[Norway Sweden])
      expect(@session).not_to have_select('Region', options: %w[Norway Norway Norway])
    end

    it 'should be true even when the options are invisible, if the select itself is invisible' do
      expect(@session).to have_select('Icecream', visible: :hidden, options: %w[Chocolate Vanilla Strawberry])
    end
  end

  context 'with enabled options' do
    it 'should be true if the listed options exist and are enabled' do
      expect(@session).to have_select('form_title', enabled_options: %w[Mr Mrs Miss])
    end

    it 'should be false if the listed options do not exist' do
      expect(@session).not_to have_select('form_title', enabled_options: ['Not there'])
    end

    it 'should be false if the listed option exists but is not enabled' do
      expect(@session).not_to have_select('form_title', enabled_options: %w[Mr Mrs Miss Other])
    end
  end

  context 'with disabled options' do
    it 'should be true if the listed options exist and are disabled' do
      expect(@session).to have_select('form_title', disabled_options: ['Other'])
    end

    it 'should be false if the listed options do not exist' do
      expect(@session).not_to have_select('form_title', disabled_options: ['Not there'])
    end

    it 'should be false if the listed option exists but is not disabled' do
      expect(@session).not_to have_select('form_title', disabled_options: %w[Other Mrs])
    end
  end

  context 'with partial options' do
    it 'should be true if a field with the given partial options is on the page' do
      expect(@session).to have_select('Region', with_options: %w[Norway Sweden])
      expect(@session).to have_select('City', with_options: ['London'])
    end

    it 'should be false if a field with the given partial options is not on the page' do
      expect(@session).not_to have_select('Locale', with_options: ['Uruguayan'])
      expect(@session).not_to have_select('Does not exist', with_options: ['John'])
      expect(@session).not_to have_select('Region', with_options: %w[Norway Sweden Finland Latvia])
    end

    it 'should be true even when the options are invisible, if the select itself is invisible' do
      expect(@session).to have_select('Icecream', visible: :hidden, with_options: %w[Vanilla Strawberry])
    end
  end

  context 'with multiple option' do
    it 'should find multiple selects if true' do
      expect(@session).to have_select('form_languages', multiple: true)
      expect(@session).not_to have_select('form_other_title', multiple: true)
    end

    it 'should not find multiple selects if false' do
      expect(@session).not_to have_select('form_languages', multiple: false)
      expect(@session).to have_select('form_other_title', multiple: false)
    end

    it 'should find both if not specified' do
      expect(@session).to have_select('form_languages')
      expect(@session).to have_select('form_other_title')
    end
  end

  it 'should support locator-less usage' do
    expect(@session.has_select?(with_options: %w[Norway Sweden])).to be true
    expect(@session).to have_select(with_options: ['London'])
    expect(@session.has_select?(with_selected: %w[Commando Boxerbriefs])).to be true
    expect(@session).to have_select(with_selected: ['Briefs'])
  end
end

Capybara::SpecHelper.spec '#has_no_select?' do
  before { @session.visit('/form') }

  it 'should be false if the field is on the page' do
    expect(@session).not_to have_no_select('Locale')
    expect(@session).not_to have_no_select('form_region')
    expect(@session).not_to have_no_select('Languages')
  end

  it 'should be true if the field is not on the page' do
    expect(@session).to have_no_select('Monkey')
  end

  context 'with selected value' do
    it 'should be false if a field with the given value is on the page' do
      expect(@session).not_to have_no_select('form_locale', selected: 'English')
      expect(@session).not_to have_no_select('Region', selected: 'Norway')
      expect(@session).not_to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end

    it 'should be true if the given field is not on the page' do
      expect(@session).to have_no_select('Locale', selected: 'Swedish')
      expect(@session).to have_no_select('Does not exist', selected: 'John')
      expect(@session).to have_no_select('City', selected: 'Not there')
      expect(@session).to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns', 'Nonexistent'
      ])
      expect(@session).to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Boxers', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
      expect(@session).to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons"
      ])
    end

    it 'should be false after the given value is selected' do
      @session.select('Swedish', from: 'Locale')
      expect(@session).not_to have_no_select('Locale', selected: 'Swedish')
    end

    it 'should be true after a different value is selected' do
      @session.select('Swedish', from: 'Locale')
      expect(@session).to have_no_select('Locale', selected: 'English')
    end

    it 'should be false after the given values are selected' do
      @session.select('Boxers', from: 'Underwear')
      expect(@session).not_to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Boxers', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end

    it 'should be true after one of the values is unselected' do
      @session.unselect('Briefs', from: 'Underwear')
      expect(@session).to have_no_select('Underwear', selected: [
        'Boxerbriefs', 'Briefs', 'Commando', "Frenchman's Pantalons", 'Long Johns'
      ])
    end
  end

  context 'with partial select' do
    it 'should be false if a field with the given partial values is on the page' do
      expect(@session).not_to have_no_select('Underwear', with_selected: %w[Boxerbriefs Briefs])
    end

    it 'should be true if a field with the given partial values is not on the page' do
      expect(@session).to have_no_select('Underwear', with_selected: %w[Boxerbriefs Boxers])
    end

    it 'should be false after the given partial value is selected' do
      @session.select('Boxers', from: 'Underwear')
      expect(@session).not_to have_no_select('Underwear', with_selected: %w[Boxerbriefs Boxers])
    end

    it 'should be true after one of the given partial values is unselected' do
      @session.unselect('Briefs', from: 'Underwear')
      expect(@session).to have_no_select('Underwear', with_selected: %w[Boxerbriefs Briefs])
    end

    it 'should support non array partial values' do
      expect(@session).not_to have_no_select('Underwear', with_selected: 'Briefs')
      expect(@session).to have_no_select('Underwear', with_selected: 'Boxers')
    end
  end

  context 'with exact options' do
    it 'should be false if a field with the given options is on the page' do
      expect(@session).not_to have_no_select('Region', options: %w[Norway Sweden Finland])
    end

    it 'should be true if the given field is not on the page' do
      expect(@session).to have_no_select('Locale', options: ['Swedish'])
      expect(@session).to have_no_select('Does not exist', options: ['John'])
      expect(@session).to have_no_select('City', options: ['London', 'Made up city'])
      expect(@session).to have_no_select('Region', options: %w[Norway Sweden])
      expect(@session).to have_no_select('Region', options: %w[Norway Norway Norway])
    end
  end

  context 'with partial options' do
    it 'should be false if a field with the given partial options is on the page' do
      expect(@session).not_to have_no_select('Region', with_options: %w[Norway Sweden])
      expect(@session).not_to have_no_select('City', with_options: ['London'])
    end

    it 'should be true if a field with the given partial options is not on the page' do
      expect(@session).to have_no_select('Locale', with_options: ['Uruguayan'])
      expect(@session).to have_no_select('Does not exist', with_options: ['John'])
      expect(@session).to have_no_select('Region', with_options: %w[Norway Sweden Finland Latvia])
    end
  end

  it 'should support locator-less usage' do
    expect(@session.has_no_select?(with_options: %w[Norway Sweden Finland Latvia])).to be true
    expect(@session).to have_no_select(with_options: ['New London'])
    expect(@session.has_no_select?(id: 'form_underwear', with_selected: ['Boxers'])).to be true
    expect(@session).to have_no_select(id: 'form_underwear', with_selected: %w[Commando Boxers])
  end
end
