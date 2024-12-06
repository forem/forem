# frozen_string_literal: true

module Modis
  module Persistence
    def self.included(base)
      base.extend ClassMethods
      base.instance_eval do
        class << self
          attr_reader :sti_child
          alias sti_child? sti_child
        end
      end
    end

    module ClassMethods
      # :nodoc:
      def bootstrap_sti(parent, child)
        child.instance_eval do
          parent.instance_eval do
            class << self
              attr_accessor :sti_base, :sti_parent
            end
            attribute :type, :string unless attributes.key?('type')
          end

          @sti_child = true
          @sti_parent = parent
          @sti_base = parent.sti_base || parent

          bootstrap_attributes(parent)
          bootstrap_indexes(parent)
        end
      end

      def namespace
        @namespace ||= if sti_child?
                         "#{sti_parent.namespace}:#{name.split('::').last.underscore}"
                       else
                         name.split('::').map(&:underscore).join(':')
                       end
      end

      def namespace=(value)
        @namespace = value
        @absolute_namespace = nil
      end

      def absolute_namespace
        @absolute_namespace ||= [Modis.config.namespace, namespace].compact.join(':')
      end

      def sti_base_absolute_namespace
        @sti_base_absolute_namespace ||= [Modis.config.namespace, sti_base.namespace].compact.join(':')
      end

      def key_for(id)
        "#{absolute_namespace}:#{id}"
      end

      def sti_base_key_for(id)
        "#{sti_base_absolute_namespace}:#{id}"
      end

      def enable_all_index(bool)
        @use_all_index = bool
      end

      def all_index_enabled?
        @use_all_index == true || @use_all_index.nil?
      end

      def create(attrs)
        model = new(attrs)
        model.save
        model
      end

      def create!(attrs)
        model = new(attrs)
        model.save!
        model
      end

      def deserialize(record)
        values = record.values
        values = MessagePack.unpack(msgpack_array_header(values.size) + values.join)
        keys = record.keys
        values.each_with_index { |v, i| record[keys[i]] = v }
        record
      rescue MessagePack::MalformedFormatError
        record.each do |k, v|
          record[k] = MessagePack.unpack(v)
        end

        record
      end

      private

      def msgpack_array_header(values_size)
        if values_size < 16
          [0x90 | values_size].pack("C")
        elsif values_size < 65536
          [0xDC, values_size].pack("Cn")
        else
          [0xDD, values_size].pack("CN")
        end.force_encoding(Encoding::UTF_8)
      end
    end

    def persisted?
      true
    end

    def key
      return nil if new_record?

      self.class.sti_child? ? self.class.sti_base_key_for(id) : self.class.key_for(id)
    end

    def new_record?
      defined?(@new_record) ? @new_record : true
    end

    def save(args = {})
      create_or_update(args)
    rescue Modis::RecordInvalid
      false
    end

    def save!(args = {})
      create_or_update(args) || (raise RecordNotSaved)
    end

    def destroy
      self.class.transaction do |redis|
        run_callbacks :destroy do
          redis.pipelined do |pipeline|
            remove_from_indexes(pipeline)
            if self.class.all_index_enabled?
              pipeline.srem(self.class.key_for(:all), id)
              pipeline.srem(self.class.sti_base_key_for(:all), id) if self.class.sti_child?
            end
            pipeline.del(key)
          end
        end
      end
    end

    def reload
      new_attributes = Modis.with_connection { |redis| self.class.attributes_for(redis, id) }
      initialize(new_attributes)
      self
    end

    def update_attribute(name, value)
      assign_attributes(name => value)
      save(validate: false)
    end

    def update(attrs)
      assign_attributes(attrs)
      save
    end

    alias update_attributes update
    deprecate update_attributes: 'please, use update instead'

    def update!(attrs)
      assign_attributes(attrs)
      save!
    end

    alias update_attributes! update!
    deprecate update_attributes!: 'please, use update! instead'

    private

    def coerce_for_persistence(value)
      value = [value.year, value.month, value.day, value.hour, value.min, value.sec, value.strftime("%:z")] if value.is_a?(Time)
      MessagePack.pack(value)
    end

    def create_or_update(args = {})
      validate(args)
      future = persist

      if future && ((future.is_a?(Symbol) && future == :unchanged) || future.value == 'OK')
        changes_applied
        @new_record = false
        true
      else
        false
      end
    end

    def validate(args)
      skip_validate = args.key?(:validate) && args[:validate] == false
      return if skip_validate || valid?

      raise Modis::RecordInvalid, errors.full_messages.join(', ')
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def persist
      future = nil
      set_id if new_record?
      callback = new_record? ? :create : :update

      self.class.transaction do |redis|
        run_callbacks :save do
          run_callbacks callback do
            redis.pipelined do |pipeline|
              attrs = coerced_attributes
              key = self.class.sti_child? ? self.class.sti_base_key_for(id) : self.class.key_for(id)
              future = attrs.any? ? pipeline.hmset(key, attrs) : :unchanged

              if new_record?
                if self.class.all_index_enabled?
                  pipeline.sadd(self.class.key_for(:all), id)
                  pipeline.sadd(self.class.sti_base_key_for(:all), id) if self.class.sti_child?
                end
                add_to_indexes(pipeline)
              else
                update_indexes(pipeline)
              end
            end
          end
        end
      end

      future
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    def coerced_attributes
      attrs = []

      if new_record?
        attributes.each do |k, v|
          attrs << k << coerce_for_persistence(v) if (self.class.attributes[k][:default] || nil) != v
        end
      else
        changed_attributes.each_key do |key|
          attrs << key << coerce_for_persistence(attributes[key])
        end
      end

      attrs
    end

    def set_id
      namespace = self.class.sti_child? ? self.class.sti_base_absolute_namespace : self.class.absolute_namespace
      Modis.with_connection do |redis|
        self.id = redis.incr("#{namespace}_id_seq")
      end
    end
  end
end
