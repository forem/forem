# frozen_string_literal: true

Capybara::SpecHelper.spec '#body' do
  it 'should return the unmodified page body' do
    @session.visit('/')
    expect(@session).to have_content('Hello world!') # wait for content to appear if visit is async
    expect(@session.body).to include('Hello world!')
  end

  context 'encoding of response between ascii and utf8' do
    it 'should be valid with html entities' do
      @session.visit('/with_html_entities')
      expect(@session).to have_content('Encoding') # wait for content to appear if visit is async
      expect { @session.body.encode!('UTF-8') }.not_to raise_error
    end

    it 'should be valid without html entities' do
      @session.visit('/with_html')
      expect(@session).to have_content('This is a test') # wait for content to appear if visit is async
      expect { @session.body.encode!('UTF-8') }.not_to raise_error
    end
  end
end
