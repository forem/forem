class Secret < ApplicationRecord
  # This class exists to take advantage of Rolify for limiting authorization
  # on internal vault secrets.
  # NOTE: It is not backed by a database table and should not be expected to
  # function like a traditional Rails model
  resourcify
end
