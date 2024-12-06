# frozen_string_literal: true

Capybara::SpecHelper.spec '#accept_prompt', requires: [:modals] do
  before do
    @session.visit('/with_js')
  end

  it 'should accept the prompt with no message' do
    @session.accept_prompt do
      @session.click_link('Open prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt' and @response='']")
  end

  it 'should accept the prompt with no message when there is a default' do
    @session.accept_prompt do
      @session.click_link('Open defaulted prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt-with-default' and @response='Default value!']")
  end

  it 'should return the message presented' do
    message = @session.accept_prompt do
      @session.click_link('Open prompt')
    end
    expect(message).to eq('Prompt opened')
  end

  it 'should accept the prompt with a response' do
    @session.accept_prompt with: 'the response' do
      @session.click_link('Open prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt' and @response='the response']")
  end

  it 'should accept the prompt with a response when there is a default' do
    @session.accept_prompt with: 'the response' do
      @session.click_link('Open defaulted prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt-with-default' and @response='the response']")
  end

  it 'should accept the prompt with a blank response when there is a default' do
    @session.accept_prompt with: '' do
      @session.click_link('Open defaulted prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt-with-default' and @response='']")
  end

  it 'should allow special characters in the reponse' do
    @session.accept_prompt with: '\'the\' \b "response"' do
      @session.click_link('Open prompt')
    end
    expect(@session).to have_xpath(%{//a[@id='open-prompt' and @response=concat("'the' ", '\\b "response"')]})
  end

  it 'should accept the prompt if the message matches' do
    @session.accept_prompt 'Prompt opened', with: 'matched' do
      @session.click_link('Open prompt')
    end
    expect(@session).to have_xpath("//a[@id='open-prompt' and @response='matched']")
  end

  it "should not accept the prompt if the message doesn't match" do
    expect do
      @session.accept_prompt 'Incorrect Text', with: 'not matched' do
        @session.click_link('Open prompt')
      end
    end.to raise_error(Capybara::ModalNotFound)
  end

  it 'should return the message presented' do
    message = @session.accept_prompt with: 'the response' do
      @session.click_link('Open prompt')
    end
    expect(message).to eq('Prompt opened')
  end
end
