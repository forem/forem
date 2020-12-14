module StringToBoolean
  refine String do
    def to_boolean
      ActiveModel::Type::Boolean.new.cast(self)
    end
  end
end
