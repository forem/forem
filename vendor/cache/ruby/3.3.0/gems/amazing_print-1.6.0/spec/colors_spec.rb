# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock, Style/OptionalBooleanParameter

require 'spec_helper'

RSpec.describe 'AmazingPrint' do
  def stub_tty!(output = true, stream = $stdout)
    if output
      stream.instance_eval do
        def tty?
          true
        end
      end
    else
      stream.instance_eval do
        def tty?
          false
        end
      end
    end
  end

  describe 'colorization' do
    PLAIN = '[ 1, :two, "three", [ nil, [ true, false ] ] ]'
    COLORIZED = "[ \e[1;34m1\e[0m, \e[0;36m:two\e[0m, \e[0;33m\"three\"\e[0m, [ \e[1;31mnil\e[0m, [ \e[1;32mtrue\e[0m, \e[1;31mfalse\e[0m ] ] ]"

    before do
      ENV['TERM'] = 'xterm-colors'
      ENV.delete('ANSICON')
      @arr = [1, :two, 'three', [nil, [true, false]]]
    end

    describe 'default settings (no forced colors)' do
      before do
        AmazingPrint.force_colors! colors: false
      end

      it 'colorizes tty processes by default' do
        stub_tty!
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      end

      it "colorizes processes with ENV['ANSICON'] by default" do
        stub_tty!
        term = ENV['ANSICON']
        ENV['ANSICON'] = '1'
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      ensure
        ENV['ANSICON'] = term
      end

      it 'does not colorize tty processes running in dumb terminals by default' do
        stub_tty!
        term = ENV['TERM']
        ENV['TERM'] = 'dumb'
        expect(@arr.ai(multiline: false)).to eq(PLAIN)
      ensure
        ENV['TERM'] = term
      end

      it 'does not colorize subprocesses by default' do
        stub_tty! false
        expect(@arr.ai(multiline: false)).to eq(PLAIN)
      ensure
        stub_tty!
      end
    end

    describe 'forced colors override' do
      before do
        AmazingPrint.force_colors!
      end

      it 'still colorizes tty processes' do
        stub_tty!
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      end

      it "colorizes processes with ENV['ANSICON'] set to 0" do
        stub_tty!
        term = ENV['ANSICON']
        ENV['ANSICON'] = '1'
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      ensure
        ENV['ANSICON'] = term
      end

      it 'colorizes dumb terminals' do
        stub_tty!
        term = ENV['TERM']
        ENV['TERM'] = 'dumb'
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      ensure
        ENV['TERM'] = term
      end

      it 'colorizes subprocess' do
        stub_tty! false
        expect(@arr.ai(multiline: false)).to eq(COLORIZED)
      ensure
        stub_tty!
      end
    end
  end

  describe 'AmazingPrint::Colors' do
    %i[gray red green yellow blue purple cyan white].each_with_index do |color, i|
      it "has #{color} color" do
        expect(AmazingPrint::Colors.public_send(color, color.to_s)).to eq("\e[1;#{i + 30}m#{color}\e[0m")
      end

      it "has #{color}ish color" do
        expect(AmazingPrint::Colors.public_send(:"#{color}ish", color.to_s)).to eq("\e[0;#{i + 30}m#{color}\e[0m")
      end
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock, Style/OptionalBooleanParameter
