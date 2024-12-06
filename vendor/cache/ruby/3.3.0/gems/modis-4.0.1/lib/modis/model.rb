# frozen_string_literal: true

module Modis
  module Model
    def self.included(base)
      base.instance_eval do
        include ActiveModel::Dirty
        include ActiveModel::Validations
        include ActiveModel::Serialization

        extend ActiveModel::Naming
        extend ActiveModel::Callbacks

        define_model_callbacks :save, :create, :update, :destroy

        include Modis::Errors
        include Modis::Transaction
        include Modis::Persistence
        include Modis::Finder
        include Modis::Attribute
        include Modis::Index

        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def inherited(child)
        super
        bootstrap_sti(self, child)
      end
    end

    def initialize(record = nil, options = {})
      apply_defaults
      set_sti_type
      assign_attributes(record) if record
      changes_applied

      return unless options.key?(:new_record)

      instance_variable_set('@new_record', options[:new_record])
    end

    def ==(other)
      super || other.instance_of?(self.class) && id.present? && other.id == id
    end
    alias eql? ==
  end
end
