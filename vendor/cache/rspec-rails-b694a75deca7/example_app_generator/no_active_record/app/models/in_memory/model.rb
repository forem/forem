raise "ActiveRecord is defined but should not be!" if defined?(::ActiveRecord)

module InMemory
  module Persistence
    def all
      @all_records ||= []
    end

    def count
      all.length
    end
    alias_method :size, :count
    alias_method :length, :count

    def last
      all.last
    end

    def find(id)
      id = id.to_i
      all.find { |record| record.id == id } || raise
    end

    def create!(attributes = {})
      record = new(attributes)
      record.save
      record
    end

    def next_id
      @id_count ||= 0
      @id_count += 1
    end
  end

  class Model
    extend Persistence

    if defined?(::ActiveModel::Model)
      include ::ActiveModel::Model
    else
      extend ::ActiveModel::Naming
      include ::ActiveModel::Conversion
      include ::ActiveModel::Validations

      def initialize(attributes = {})
        assign_attributes(attributes)
      end
    end

    attr_accessor :id, :persisted

    alias_method :persisted?, :persisted

    def update(attributes)
      assign_attributes(attributes)
      save
    end

    alias_method :update_attributes, :update

    def assign_attributes(attributes)
      attributes.each do |name, value|
        __send__("#{name}=", value)
      end
    end

    def save(*)
      self.id = self.class.next_id
      self.class.all << self
      true
    end

    def destroy
      self.class.all.delete(self)
      true
    end

    def reload(*)
      self
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id
    end

    def persisted?
      !id.nil?
    end

    def new_record?
      !persisted?
    end

    def to_param
      id.to_s
    end
  end
end
