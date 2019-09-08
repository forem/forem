module Secrets
  module Generator
    module_function

    # Generates a unique and lexicographically sortable ID
    def sortable(time = Time.current)
      ULID.generate(time)
    end
  end
end
