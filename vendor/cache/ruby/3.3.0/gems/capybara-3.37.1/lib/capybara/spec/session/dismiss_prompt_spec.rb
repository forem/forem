# frozen_string_literal: true

Capybara::SpecHelper.spec '#dismiss_prompt', requires: [:modals] do
  before do
    @session.visit('/with_js')
  end

  it 'should dismiss the prompt' do
    @session.dismiss_prompt do
      @session.click_link('Open prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt' and @response='dismissed']")
  end

  it 'should return the message presented' do
    message = @session.dismiss_prompt do
      @session.click_link('Open prompt')
    end
    expect(message).to eq('Prompt opened')
  end
end
