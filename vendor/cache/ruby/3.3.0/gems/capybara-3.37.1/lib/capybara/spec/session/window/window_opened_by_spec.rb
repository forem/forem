# frozen_string_literal: true

# NOTE: This file uses `sleep` to sync up parts of the tests. This is only implemented like this
# because of the methods being tested. In tests using Capybara this type of behavior should be implemented
# using Capybara provided assertions with builtin waiting behavior.

Capybara::SpecHelper.spec '#window_opened_by', requires: [:windows] do
  before do
    @window = @session.current_window
    @session.visit('/with_windows')
    @session.assert_selector(:css, 'body.loaded')
  end

  after do
    (@session.windows - [@window]).each do |w|
      @session.switch_to_window w
      w.close
    end
    @session.switch_to_window(@window)
  end

  let(:zero_windows_message) { 'block passed to #window_opened_by opened 0 windows instead of 1' }
  let(:two_windows_message) { 'block passed to #window_opened_by opened 2 windows instead of 1' }

  context 'with :wait option' do
    it 'should raise error if value of :wait is less than timeout' do
      # So large value is used as `driver.window_handles` takes up to 800 ms on Travis
      Capybara.using_wait_time 2 do
        button = @session.find(:css, '#openWindowWithLongerTimeout')
        expect do
          @session.window_opened_by(wait: 0.3) do
            button.click
          end
        end.to raise_error(Capybara::WindowError, zero_windows_message)
      end
      @session.document.synchronize(5, errors: [Capybara::CapybaraError]) do
        raise Capybara::CapybaraError if @session.windows.size != 2
      end
    end

    it 'should find window if value of :wait is more than timeout' do
      button = @session.find(:css, '#openWindowWithTimeout')
      Capybara.using_wait_time 0.1 do
        window = @session.window_opened_by(wait: 1.5) do
          button.click
        end
        expect(window).to be_instance_of(Capybara::Window)
      end
    end
  end

  context 'without :wait option' do
    it 'should raise error if default_max_wait_time is less than timeout' do
      button = @session.find(:css, '#openWindowWithTimeout')
      Capybara.using_wait_time 0.1 do
        expect do
          @session.window_opened_by do
            button.click
          end
        end.to raise_error(Capybara::WindowError, zero_windows_message)
      end
      @session.document.synchronize(2, errors: [Capybara::CapybaraError]) do
        raise Capybara::CapybaraError if @session.windows.size != 2
      end
    end

    it 'should find window if default_max_wait_time is more than timeout' do
      button = @session.find(:css, '#openWindowWithTimeout')
      Capybara.using_wait_time 5 do
        window = @session.window_opened_by do
          button.click
        end
        expect(window).to be_instance_of(Capybara::Window)
      end
    end
  end

  it 'should raise error when two windows have been opened by block' do
    button = @session.find(:css, '#openTwoWindows')
    expect do
      @session.window_opened_by do
        button.click
        sleep 1 # It's possible for window_opened_by to be fullfilled before the second window opens
      end
    end.to raise_error(Capybara::WindowError, two_windows_message)
    @session.document.synchronize(2, errors: [Capybara::CapybaraError]) do
      raise Capybara::CapybaraError if @session.windows.size != 3
    end
  end

  it 'should raise error when no windows were opened by block' do
    button = @session.find(:css, '#doesNotOpenWindows')
    expect do
      @session.window_opened_by do
        button.click
      end
    end.to raise_error(Capybara::WindowError, zero_windows_message)
  end
end
