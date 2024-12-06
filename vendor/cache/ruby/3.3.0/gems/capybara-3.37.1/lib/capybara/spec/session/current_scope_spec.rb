# frozen_string_literal: true

Capybara::SpecHelper.spec '#current_scope' do
  before do
    @session.visit('/with_scope')
  end

  context 'when not in a #within block' do
    it 'should return the document' do
      expect(@session.current_scope).to be_kind_of Capybara::Node::Document
    end
  end

  context 'when in a #within block' do
    it 'should return the element in scope' do
      @session.within(:css, '#simple_first_name') do
        expect(@session.current_scope[:name]).to eq 'first_name'
      end
    end
  end

  context 'when in a nested #within block' do
    it 'should return the element in scope' do
      @session.within("//div[@id='for_bar']") do
        @session.within(".//input[@value='Peter']") do
          expect(@session.current_scope[:name]).to eq 'form[first_name]'
        end
      end
    end
  end
end
