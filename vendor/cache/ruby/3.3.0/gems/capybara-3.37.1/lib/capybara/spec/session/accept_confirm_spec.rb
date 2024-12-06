# frozen_string_literal: true

Capybara::SpecHelper.spec '#accept_confirm', requires: [:modals] do
  before do
    @session.visit('/with_js')
  end

  it 'should accept the confirm' do
    @session.accept_confirm do
      @session.click_link('Open confirm')
    end
    expect(@session).to have_xpath("//a[@id='open-confirm' and @confirmed='true']")
  end

  it 'should return the message presented' do
    message = @session.accept_confirm do
      @session.click_link('Open confirm')
    end
    expect(message).to eq('Confirm opened')
  end

  it 'should work with nested modals' do
    expect do
      @session.dismiss_confirm 'Are you really sure?' do
        @session.accept_confirm 'Are you sure?' do
          @session.click_link('Open check twice')
        end
      end
    end.not_to raise_error
    expect(@session).to have_xpath("//a[@id='open-twice' and @confirmed='false']")
  end
end
