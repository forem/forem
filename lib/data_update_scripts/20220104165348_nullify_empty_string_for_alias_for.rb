module DataUpdateScripts
  class NullifyEmptyStringForAliasFor
    def run
      Tag.where(alias_for: "").update_all(alias_for: nil)
    end
  end
end
