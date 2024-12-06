# frozen_string_literal: true

require 'spec_helper'

require 'logger'
require 'amazing_print/core_ext/logger'

RSpec.describe 'AmazingPrint logging extensions' do
  subject(:logger) do
    Logger.new('/dev/null')
  rescue Errno::ENOENT
    Logger.new('nul')
  end

  let(:object) { double }
  let(:options) { { sort_keys: true } }

  describe 'ap method' do
    it 'awesome_inspects the given object' do
      expect(object).to receive(:ai)
      logger.ap object
    end

    it 'passes options to `ai`' do
      expect(object).to receive(:ai).with(options)
      logger.ap object, options
    end

    describe 'the log level' do
      before do
        AmazingPrint.defaults = {}
      end

      it 'fallbacks to the default :debug log level' do
        expect(logger).to receive(:debug)
        logger.ap nil
      end

      it 'uses the global user default if no level passed' do
        AmazingPrint.defaults = { log_level: :info }
        expect(logger).to receive(:info)
        logger.ap nil
      end

      it 'uses the passed in level' do
        expect(logger).to receive(:warn)
        logger.ap nil, :warn
      end

      it 'makes no difference if passed as a hash or a part of options' do
        expect(logger).to receive(:warn)
        logger.ap nil, { level: :warn }
      end

      context 'when given options' do
        it 'uses the default log level with the options' do
          expect(logger).to receive(:debug)
          expect(object).to receive(:ai).with(options)
          logger.ap object, options
        end

        it 'still uses the passed in level with options' do
          expect(logger).to receive(:warn)
          expect(object).to receive(:ai).with(options)
          logger.ap object, options.merge({ level: :warn })
        end
      end
    end
  end
end
