# frozen_string_literal: true

Capybara::SpecHelper.spec '#title' do
  it 'should get the title of the page' do
    @session.visit('/with_title')
    expect(@session.title).to eq('Test Title')
  end

  context 'with css as default selector' do
    before { Capybara.default_selector = :css }

    after { Capybara.default_selector = :xpath }

    it 'should get the title of the page' do
      @session.visit('/with_title')
      expect(@session.title).to eq('Test Title')
    end
  end

  context 'within iframe', requires: [:frames] do
    it 'should get the title of the top level browsing context' do
      @session.visit('/within_frames')
      expect(@session.title).to eq('With Frames')
      @session.within_frame('frameOne') do
        expect(@session.title).to eq('With Frames')
      end
    end
  end
end
