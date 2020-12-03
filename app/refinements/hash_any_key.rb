module HashAnyKey
  refine Hash do
    def any_key?(keys)
      (keys & Array.wrap(keys)).any?
    end
  end
end
