require 'active_support'

module CarrierWave
  module Uploader
    module FileSize
      extend ActiveSupport::Concern

      included do
        before :cache, :check_size!
      end

      ##
      # Override this method in your uploader to provide a Range of Size which
      # are allowed to be uploaded.
      # === Returns
      #
      # [NilClass, Range] a size range which are permitted to be uploaded
      #
      # === Examples
      #
      #     def size_range
      #       3256...5748
      #     end
      #
      def size_range; end

      private

      def check_size!(new_file)
        size = new_file.size
        expected_size_range = size_range
        if expected_size_range.is_a?(::Range)
          if size < expected_size_range.min
            raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.min_size_error", :min_size => ActiveSupport::NumberHelper.number_to_human_size(expected_size_range.min))
          elsif size > expected_size_range.max
            raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.max_size_error", :max_size => ActiveSupport::NumberHelper.number_to_human_size(expected_size_range.max))
          end
        end
      end

    end # FileSize
  end # Uploader
end # CarrierWave
