require 'active_record'
require 'carrierwave/validations/active_model'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      mod = Module.new
      prepend mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_url=(url)
          column = _mounter(:#{column}).serialization_column
          __send__(:"\#{column}_will_change!")
          super
        end
      RUBY
    end

    ##
    # See +CarrierWave::Mount#mount_uploaders+ for documentation
    #
    def mount_uploaders(column, uploader=nil, options={}, &block)
      super

      mod = Module.new
      prepend mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_urls=(url)
          column = _mounter(:#{column}).serialization_column
          __send__(:"\#{column}_will_change!")
          super
        end
      RUBY
    end

  private

    def mount_base(column, uploader=nil, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute
      public :read_uploader
      public :write_uploader

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      validates_download_of column if uploader_option(column.to_sym, :validate_download)

      before_save :"write_#{column}_identifier"
      after_save :"store_previous_changes_for_#{column}"
      after_commit :"remove_#{column}!", :on => :destroy
      after_commit :"mark_remove_#{column}_false", :on => :update
      after_commit :"remove_previously_stored_#{column}", :on => :update
      after_commit :"store_#{column}!", :on => [:create, :update]

      mod = Module.new
      prepend mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          if !(new_file.blank? && __send__(:#{column}).blank?)
            __send__(:"\#{column}_will_change!")
          end

          super
        end

        def remove_#{column}=(value)
          column = _mounter(:#{column}).serialization_column
          result = super
          __send__(:"\#{column}_will_change!") if _mounter(:#{column}).remove?
          result
        end

        def remove_#{column}!
          self.remove_#{column} = true
          write_#{column}_identifier
          self.remove_#{column} = false
          super
        end

        # Reset cached mounter on record reload
        def reload(*)
          @_mounters = nil
          super
        end

        # Reset cached mounter on record dup
        def initialize_dup(other)
          @_mounters = nil
          super
        end
      RUBY
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord
