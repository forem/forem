module StringToBool
  refine String do
    def to_bool
      ActiveModel::Type::Boolean.new.cast(self)
    end
  end
end
