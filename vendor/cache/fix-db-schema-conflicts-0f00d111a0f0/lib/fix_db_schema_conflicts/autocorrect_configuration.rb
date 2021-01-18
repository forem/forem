module FixDBSchemaConflicts
  class AutocorrectConfiguration
    def self.load
      new.load
    end

    def load
      if less_than_rubocop?(49)
        '.rubocop_schema.yml'
      elsif less_than_rubocop?(53)
        '.rubocop_schema.49.yml'
      else
        '.rubocop_schema.53.yml'
      end
    end

    private

    def less_than_rubocop?(ver)
      Gem.loaded_specs['rubocop'].version < Gem::Version.new("0.#{ver}.0")
    end
  end
end
