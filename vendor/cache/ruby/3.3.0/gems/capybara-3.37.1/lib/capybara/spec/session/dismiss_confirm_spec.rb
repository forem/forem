# frozen_string_literal: true

Capybara::SpecHelper.spec '#dismiss_confirm', requires: [:modals] do
  before do
    @session.visit('/with_js')
  end

  it 'should dismiss the confirm' do
    @session.dismiss_confirm do
      @session.click_link('Open confirm')
    end
    expect(@session).to have_xpath("//a[@id='open-confirm' and @confirmed='false']")
  end

  it 'should dismiss the confirm if the message matches' do
    @session.dismiss_confirm 'Confirm opened' do
      @session.click_link('Open confirm')
    end
    expect(@session).to have_xpath("//a[@id='open-confirm' and @confirmed='false']")
  end

  it "should not dismiss the confirm if the message doesn't match" do
    expect do
      @session.dismiss_confirm 'Incorrect Text' do
        @session.click_link('Open confirm')
      end
    end.to raise_error(Capybara::ModalNotFound)
  end

  it 'should return the message presented' do
    message = @session.dismiss_confirm do
      @session.click_link('Open confirm')
    end
    expect(message).to eq('Confirm opened')
  end
end
