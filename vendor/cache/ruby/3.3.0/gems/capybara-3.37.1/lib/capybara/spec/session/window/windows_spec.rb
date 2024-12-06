# frozen_string_literal: true

# NOTE: This file uses `sleep` to sync up parts of the tests. This is only implemented like this
# because of the methods being tested. In tests using Capybara this type of behavior should be implemented
# using Capybara provided assertions with builtin waiting behavior.

Capybara::SpecHelper.spec '#windows', requires: [:windows] do
  before do
    @window = @session.current_window
    @session.visit('/with_windows')
    @session.find(:css, '#openTwoWindows').click

    @session.document.synchronize(3, errors: [Capybara::CapybaraError]) do
      raise Capybara::CapybaraError if @session.windows.size != 3
    end
  end

  after do
    (@session.windows - [@window]).each(&:close)
    @session.switch_to_window(@window)
  end

  it 'should return objects of Capybara::Window class' do
    expect(@session.windows.map { |window| window.instance_of?(Capybara::Window) }).to eq([true] * 3)
  end

  it 'should be able to switch to windows' do
    sleep 1 # give windows enough time to fully load
    titles = @session.windows.map do |window|
      @session.within_window(window) { @session.title }
    end
    expect(titles).to match_array(['With Windows', 'Title of the first popup', 'Title of popup two'])
  end
end
