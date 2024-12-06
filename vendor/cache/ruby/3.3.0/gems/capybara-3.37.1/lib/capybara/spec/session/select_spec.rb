# frozen_string_literal: true

Capybara::SpecHelper.spec '#select' do
  before do
    @session.visit('/form')
  end

  it 'should return value of the first option' do
    expect(@session.find_field('Title').value).to eq('Mrs')
  end

  it 'should return value of the selected option' do
    @session.select('Miss', from: 'Title')
    expect(@session.find_field('Title').value).to eq('Miss')
  end

  it 'should allow selecting exact options where there are inexact matches', :exact_false do
    @session.select('Mr', from: 'Title')
    expect(@session.find_field('Title').value).to eq('Mr')
  end

  it 'should allow selecting options where they are the only inexact match', :exact_false do
    @session.select('Mis', from: 'Title')
    expect(@session.find_field('Title').value).to eq('Miss')
  end

  it 'should not allow selecting options where they are the only inexact match if `exact: true` is specified' do
    sel = @session.find(:select, 'Title')
    expect do
      sel.select('Mis', exact: true)
    end.to raise_error(Capybara::ElementNotFound)
  end

  it 'should not allow selecting an option if the match is ambiguous', :exact_false do
    expect do
      @session.select('M', from: 'Title')
    end.to raise_error(Capybara::Ambiguous)
  end

  it 'should return the value attribute rather than content if present' do
    expect(@session.find_field('Locale').value).to eq('en')
  end

  it 'should select an option from a select box by id' do
    @session.select('Finnish', from: 'form_locale')
    @session.click_button('awesome')
    expect(extract_results(@session)['locale']).to eq('fi')
  end

  it 'should select an option from a select box by label' do
    @session.select('Finnish', from: 'Locale')
    @session.click_button('awesome')
    expect(extract_results(@session)['locale']).to eq('fi')
  end

  it 'should select an option without giving a select box' do
    @session.select('Swedish')
    @session.click_button('awesome')
    expect(extract_results(@session)['locale']).to eq('sv')
  end

  it 'should escape quotes' do
    @session.select("John's made-up language", from: 'Locale')
    @session.click_button('awesome')
    expect(extract_results(@session)['locale']).to eq('jo')
  end

  it 'should obey from' do
    @session.select('Miss', from: 'Other title')
    @session.click_button('awesome')
    results = extract_results(@session)
    expect(results['other_title']).to eq('Miss')
    expect(results['title']).not_to eq('Miss')
  end

  it 'show match labels with preceding or trailing whitespace' do
    @session.select('Lojban', from: 'Locale')
    @session.click_button('awesome')
    expect(extract_results(@session)['locale']).to eq('jbo')
  end

  it 'casts to string' do
    @session.select(:Miss, from: :Title)
    expect(@session.find_field('Title').value).to eq('Miss')
  end

  context 'input with datalist' do
    it 'should select an option' do
      @session.select('Audi', from: 'manufacturer')
      @session.click_button('awesome')
      expect(extract_results(@session)['manufacturer']).to eq('Audi')
    end

    it 'should not find an input without a datalist' do
      expect do
        @session.select('Thomas', from: 'form_first_name')
      end.to raise_error(/Unable to find input box with datalist completion "form_first_name"/)
    end

    it "should not select an option that doesn't exist" do
      expect do
        @session.select('Tata', from: 'manufacturer')
      end.to raise_error(/Unable to find datalist option "Tata"/)
    end

    it 'should not select a disabled option' do
      expect do
        @session.select('Mercedes', from: 'manufacturer')
      end.to raise_error(/Unable to find datalist option "Mercedes"/)
    end
  end

  context "with a locator that doesn't exist" do
    it 'should raise an error' do
      msg = /Unable to find select box "does not exist"/
      expect do
        @session.select('foo', from: 'does not exist')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context "with an option that doesn't exist" do
    it 'should raise an error' do
      msg = /^Unable to find option "Does not Exist" within/
      expect do
        @session.select('Does not Exist', from: 'form_locale')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'on a disabled select' do
    it 'should raise an error' do
      expect do
        @session.select('Should not see me', from: 'Disabled Select')
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'on a disabled option' do
    it 'should not select' do
      @session.select('Other', from: 'form_title')
      expect(@session.find_field('form_title').value).not_to eq 'Other'
    end
  end

  context 'with multiple select' do
    it 'should return an empty value' do
      expect(@session.find_field('Languages').value).to eq([])
    end

    it 'should return value of the selected options' do
      @session.select('Ruby',       from: 'Languages')
      @session.select('Javascript', from: 'Languages')
      expect(@session.find_field('Languages').value).to include('Ruby', 'Javascript')
    end

    it 'should select one option' do
      @session.select('Ruby', from: 'Languages')
      @session.click_button('awesome')
      expect(extract_results(@session)['languages']).to eq(['Ruby'])
    end

    it 'should select multiple options' do
      @session.select('Ruby',       from: 'Languages')
      @session.select('Javascript', from: 'Languages')
      @session.click_button('awesome')
      expect(extract_results(@session)['languages']).to include('Ruby', 'Javascript')
    end

    it 'should remain selected if already selected' do
      @session.select('Ruby',       from: 'Languages')
      @session.select('Javascript', from: 'Languages')
      @session.select('Ruby',       from: 'Languages')
      @session.click_button('awesome')
      expect(extract_results(@session)['languages']).to include('Ruby', 'Javascript')
    end

    it 'should return value attribute rather than content if present' do
      expect(@session.find_field('Underwear').value).to include('thermal')
    end
  end

  context 'with :exact option' do
    context 'when `false`' do
      it 'can match select box approximately' do
        @session.select('Finnish', from: 'Loc', exact: false)
        @session.click_button('awesome')
        expect(extract_results(@session)['locale']).to eq('fi')
      end

      it 'can match option approximately' do
        @session.select('Fin', from: 'Locale', exact:  false)
        @session.click_button('awesome')
        expect(extract_results(@session)['locale']).to eq('fi')
      end

      it 'can match option approximately when :from not given' do
        @session.select('made-up language', exact:  false)
        @session.click_button('awesome')
        expect(extract_results(@session)['locale']).to eq('jo')
      end
    end

    context 'when `true`' do
      it 'can match select box approximately' do
        expect do
          @session.select('Finnish', from: 'Loc', exact: true)
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'can match option approximately' do
        expect do
          @session.select('Fin', from: 'Locale', exact: true)
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'can match option approximately when :from not given' do
        expect do
          @session.select('made-up language', exact: true)
        end.to raise_error(Capybara::ElementNotFound)
      end
    end
  end

  it 'should error when not passed a locator for :from option' do
    select = @session.find(:select, 'Title')
    expect { @session.select('Mr', from: select) }.to raise_error(ArgumentError, /does not take an element/)
  end
end
