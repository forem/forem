module ISO3166
  class Country
    def subdivision_codes
      # TODO: Maybe avoid loading the full subdivisions? This works for now though.
      subdivisions.keys
    end
  end
end
