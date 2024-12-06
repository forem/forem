# frozen_string_literal: true

Capybara::SpecHelper.spec Capybara::Selector do
  before do
    @session.visit('/form')
  end

  describe ':label selector' do
    it 'finds a label by text' do
      expect(@session.find(:label, 'Customer Name').text).to eq 'Customer Name'
    end

    it 'finds a label by for attribute string' do
      expect(@session.find(:label, for: 'form_other_title')['for']).to eq 'form_other_title'
    end

    it 'finds a label for for attribute regex' do
      expect(@session.find(:label, for: /_other_title/)['for']).to eq 'form_other_title'
    end

    it 'finds a label from nested input using :for filter with id string' do
      expect(@session.find(:label, for: 'nested_label').text).to eq 'Nested Label'
    end

    it 'finds a label from nested input using :for filter with id regexp' do
      expect(@session.find(:label, for: /nested_lab/).text).to eq 'Nested Label'
    end

    it 'finds a label from nested input using :for filter with element' do
      input = @session.find(:id, 'nested_label')
      expect(@session.find(:label, for: input).text).to eq 'Nested Label'
    end

    it 'finds a label from nested input using :for filter with element when no id on label' do
      input = @session.find(:css, '#wrapper_label').find(:css, 'input')
      expect(@session.find(:label, for: input).text).to eq 'Wrapper Label'
    end

    it 'finds the label for an non-nested element when using :for filter' do
      select = @session.find(:id, 'form_other_title')
      expect(@session.find(:label, for: select)['for']).to eq 'form_other_title'
    end

    context 'with exact option' do
      it 'matches substrings' do
        expect(@session.find(:label, 'Customer Na', exact: false).text).to eq 'Customer Name'
      end

      it "doesn't match substrings" do
        expect { @session.find(:label, 'Customer Na', exact: true) }.to raise_error(Capybara::ElementNotFound)
      end
    end
  end

  describe 'field selectors' do
    context 'with :id option' do
      it 'can find specifically by id' do
        expect(@session.find(:field, id: 'customer_email').value).to eq 'ben@ben.com'
      end

      it 'can find by regex' do
        expect(@session.find(:field, id: /ustomer.emai/).value).to eq 'ben@ben.com'
      end

      it 'can find by case-insensitive id' do
        expect(@session.find(:field, id: /StOmer.emAI/i).value).to eq 'ben@ben.com'
      end
    end

    it 'can find specifically by name string' do
      expect(@session.find(:field, name: 'form[other_title]')['id']).to eq 'form_other_title'
    end

    it 'can find specifically by name regex' do
      expect(@session.find(:field, name: /form\[other_.*\]/)['id']).to eq 'form_other_title'
    end

    it 'can find specifically by placeholder string' do
      expect(@session.find(:field, placeholder: 'FirstName')['id']).to eq 'form_first_name'
    end

    it 'can find specifically by placeholder regex' do
      expect(@session.find(:field, placeholder: /FirstN.*/)['id']).to eq 'form_first_name'
    end

    it 'can find by type' do
      expect(@session.find(:field, 'Confusion', type: 'checkbox')['id']).to eq 'confusion_checkbox'
      expect(@session.find(:field, 'Confusion', type: 'text')['id']).to eq 'confusion_text'
      expect(@session.find(:field, 'Confusion', type: 'textarea')['id']).to eq 'confusion_textarea'
    end

    it 'can find by class' do
      expect(@session.find(:field, class: 'confusion-checkbox')['id']).to eq 'confusion_checkbox'
      expect(@session).to have_selector(:field, class: 'confusion', count: 3)
      expect(@session.find(:field, class: %w[confusion confusion-textarea])['id']).to eq 'confusion_textarea'
    end
  end
end
