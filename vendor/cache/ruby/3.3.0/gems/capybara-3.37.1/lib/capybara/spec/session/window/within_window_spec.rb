# frozen_string_literal: true

Capybara::SpecHelper.spec '#within_window', requires: [:windows] do
  before do
    @window = @session.current_window
    @session.visit('/with_windows')
    @session.find(:css, '#openTwoWindows').click

    @session.document.synchronize(3, errors: [Capybara::CapybaraError]) do
      raise Capybara::CapybaraError if @session.windows.size != 3
    end
  end

  after do
    (@session.windows - [@window]).each do |w|
      @session.switch_to_window w
      w.close
    end
    @session.switch_to_window(@window)
  end

  context 'with an instance of Capybara::Window' do
    it 'should not invoke driver#switch_to_window when given current window' do
      allow(@session.driver).to receive(:switch_to_window).and_call_original
      @session.within_window @window do
        expect(@session.title).to eq('With Windows')
      end
      expect(@session.driver).not_to have_received(:switch_to_window)
    end

    it 'should be able to switch to another window' do
      window = (@session.windows - [@window]).first
      @session.within_window window do
        expect(@session).to have_title(/Title of the first popup|Title of popup two/)
      end
      expect(@session.title).to eq('With Windows')
    end

    it 'returns value from the block' do
      window = (@session.windows - [@window]).first
      value = @session.within_window window do
        43252003274489856000
      end
      expect(value).to eq(43252003274489856000)
    end

    it 'should switch back if exception was raised inside block' do
      window = (@session.windows - [@window]).first
      expect do
        @session.within_window(window) do
          @session.within 'html' do
            raise 'some error'
          end
        end
      end.to raise_error(StandardError, 'some error')
      expect(@session.current_window).to eq(@window)
      expect(@session).to have_css('#doesNotOpenWindows')
      expect(@session.send(:scopes)).to eq([nil])
    end

    it 'should leave correct scopes after execution in case of error', requires: %i[windows frames] do
      window = (@session.windows - [@window]).first
      expect do
        @session.within_frame 'frameOne' do
          @session.within_window(window) {}
        end
      end.to raise_error(Capybara::ScopeError)
      expect(@session.current_window).to eq(@window)
      expect(@session).to have_css('#doesNotOpenWindows')
      expect(@session.send(:scopes)).to eq([nil])
    end

    it 'should raise error if closed window was passed' do
      other_window = (@session.windows - [@window]).first
      @session.within_window other_window do
        other_window.close
      end
      expect do
        @session.within_window(other_window) do
          raise 'should not be invoked'
        end
      end.to raise_error(@session.driver.no_such_window_error)
      expect(@session.current_window).to eq(@window)
      expect(@session).to have_css('#doesNotOpenWindows')
      expect(@session.send(:scopes)).to eq([nil])
    end
  end

  context 'with lambda' do
    it 'should find the div in another window' do
      @session.within_window(-> { @session.title == 'Title of the first popup' }) do
        expect(@session).to have_css('#divInPopupOne')
      end
    end

    it 'should find divs in both windows' do
      @session.within_window(-> { @session.title == 'Title of popup two' }) do
        expect(@session).to have_css('#divInPopupTwo')
      end
      @session.within_window(-> { @session.title == 'Title of the first popup' }) do
        expect(@session).to have_css('#divInPopupOne')
      end
      expect(@session.title).to eq('With Windows')
    end

    it 'should be able to nest within_window' do
      @session.within_window(-> { @session.title == 'Title of popup two' }) do
        expect(@session).to have_css('#divInPopupTwo')
        @session.within_window(-> { @session.title == 'Title of the first popup' }) do
          expect(@session).to have_css('#divInPopupOne')
        end
        expect(@session).to have_css('#divInPopupTwo')
        expect(@session).not_to have_css('divInPopupOne')
      end
      expect(@session).not_to have_css('#divInPopupTwo')
      expect(@session).not_to have_css('divInPopupOne')
      expect(@session.title).to eq('With Windows')
    end

    it 'should work inside a normal scope' do
      expect(@session).to have_css('#openWindow')
      @session.within(:css, '#scope') do
        @session.within_window(-> { @session.title == 'Title of the first popup' }) do
          expect(@session).to have_css('#divInPopupOne')
        end
        expect(@session).to have_content('My scoped content')
        expect(@session).not_to have_css('#openWindow')
      end
    end

    it "should raise error if window wasn't found" do
      expect do
        @session.within_window(-> { @session.title == 'Invalid title' }) do
          expect(@session).to have_css('#divInPopupOne')
        end
      end.to raise_error(Capybara::WindowError, 'Could not find a window matching block/lambda')
      expect(@session.current_window).to eq(@window)
      expect(@session).to have_css('#doesNotOpenWindows')
      expect(@session.send(:scopes)).to eq([nil])
    end

    it 'returns value from the block' do
      value = @session.within_window(-> { @session.title == 'Title of popup two' }) { 42 }
      expect(value).to eq(42)
    end

    it 'should switch back if exception was raised inside block' do
      expect do
        @session.within_window(-> { @session.title == 'Title of popup two' }) do
          raise 'some error'
        end
      end.to raise_error(StandardError, 'some error')
      expect(@session.current_window).to eq(@window)
      expect(@session.send(:scopes)).to eq([nil])
    end
  end
end
