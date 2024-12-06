# frozen_string_literal: true

Capybara::SpecHelper.spec '#unselect' do
  before do
    @session.visit('/form')
  end

  context 'with multiple select' do
    it 'should unselect an option from a select box by id' do
      @session.unselect('Commando', from: 'form_underwear')
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).to include('Briefs', 'Boxerbriefs')
      expect(extract_results(@session)['underwear']).not_to include('Commando')
    end

    it 'should unselect an option without a select box' do
      @session.unselect('Commando')
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).to include('Briefs', 'Boxerbriefs')
      expect(extract_results(@session)['underwear']).not_to include('Commando')
    end

    it 'should unselect an option from a select box by label' do
      @session.unselect('Commando', from: 'Underwear')
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).to include('Briefs', 'Boxerbriefs')
      expect(extract_results(@session)['underwear']).not_to include('Commando')
    end

    it 'should favour exact matches to option labels' do
      @session.unselect('Briefs', from: 'Underwear')
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).to include('Commando', 'Boxerbriefs')
      expect(extract_results(@session)['underwear']).not_to include('Briefs')
    end

    it 'should escape quotes' do
      @session.unselect("Frenchman's Pantalons", from: 'Underwear')
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).not_to include("Frenchman's Pantalons")
    end

    it 'casts to string' do
      @session.unselect(:Briefs, from: :Underwear)
      @session.click_button('awesome')
      expect(extract_results(@session)['underwear']).to include('Commando', 'Boxerbriefs')
      expect(extract_results(@session)['underwear']).not_to include('Briefs')
    end
  end

  context 'with single select' do
    it 'should raise an error' do
      expect { @session.unselect('English', from: 'form_locale') }.to raise_error(Capybara::UnselectNotAllowed)
    end
  end

  context "with a locator that doesn't exist" do
    it 'should raise an error' do
      msg = /Unable to find select box "does not exist"/
      expect do
        @session.unselect('foo', from: 'does not exist')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context "with an option that doesn't exist" do
    it 'should raise an error' do
      msg = /^Unable to find option "Does not Exist" within/
      expect do
        @session.unselect('Does not Exist', from: 'form_underwear')
      end.to raise_error(Capybara::ElementNotFound, msg)
    end
  end

  context 'with :exact option' do
    context 'when `false`' do
      it 'can match select box approximately' do
        @session.unselect('Boxerbriefs', from: 'Under', exact: false)
        @session.click_button('awesome')
        expect(extract_results(@session)['underwear']).not_to include('Boxerbriefs')
      end

      it 'can match option approximately' do
        @session.unselect('Boxerbr', from: 'Underwear', exact: false)
        @session.click_button('awesome')
        expect(extract_results(@session)['underwear']).not_to include('Boxerbriefs')
      end

      it 'can match option approximately when :from not given' do
        @session.unselect('Boxerbr', exact: false)
        @session.click_button('awesome')
        expect(extract_results(@session)['underwear']).not_to include('Boxerbriefs')
      end
    end

    context 'when `true`' do
      it 'can match select box approximately' do
        expect do
          @session.unselect('Boxerbriefs', from: 'Under', exact:  true)
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'can match option approximately' do
        expect do
          @session.unselect('Boxerbr', from: 'Underwear', exact:  true)
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'can match option approximately when :from not given' do
        expect do
          @session.unselect('Boxerbr', exact: true)
        end.to raise_error(Capybara::ElementNotFound)
      end
    end
  end
end
