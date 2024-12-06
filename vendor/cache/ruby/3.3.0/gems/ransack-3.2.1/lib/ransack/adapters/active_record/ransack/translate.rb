module Ransack
  module Translate

    def self.i18n_key(klass)
      klass.model_name.i18n_key
    end
  end
end
