require 'active_model/validator'
require 'active_support/concern'

module CarrierWave

  # == Active Model Presence Validator
  module Validations
    module ActiveModel
      extend ActiveSupport::Concern

      class ProcessingValidator < ::ActiveModel::EachValidator

        def validate_each(record, attribute, value)
          record.__send__("#{attribute}_processing_errors").each do |e|
            message = (e.message == e.class.to_s) ? :carrierwave_processing_error : e.message
            record.errors.add(attribute, message)
          end
        end
      end

      class IntegrityValidator < ::ActiveModel::EachValidator

        def validate_each(record, attribute, value)
          record.__send__("#{attribute}_integrity_errors").each do |e|
            message = (e.message == e.class.to_s) ? :carrierwave_integrity_error : e.message
            record.errors.add(attribute, message)
          end
        end
      end

      class DownloadValidator < ::ActiveModel::EachValidator

        def validate_each(record, attribute, value)
          record.__send__("#{attribute}_download_errors").each do |e|
            message = (e.message == e.class.to_s) ? :carrierwave_download_error : e.message
            record.errors.add(attribute, message)
          end
        end
      end

      module HelperMethods

        ##
        # Makes the record invalid if the file couldn't be uploaded due to an integrity error
        #
        # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
        #
        def validates_integrity_of(*attr_names)
          validates_with IntegrityValidator, _merge_attributes(attr_names)
        end

        ##
        # Makes the record invalid if the file couldn't be processed (assuming the process failed
        # with a CarrierWave::ProcessingError)
        #
        # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
        #
        def validates_processing_of(*attr_names)
          validates_with ProcessingValidator, _merge_attributes(attr_names)
        end
        #
        ##
        # Makes the record invalid if the remote file couldn't be downloaded
        #
        # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
        #
        def validates_download_of(*attr_names)
          validates_with DownloadValidator, _merge_attributes(attr_names)
        end
      end

      included do
        extend HelperMethods
        include HelperMethods
      end
    end
  end
end
