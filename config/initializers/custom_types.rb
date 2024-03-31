# Custom ActiveRecord types, for example mapping from a Postgres database extension type to a Ruby object
Rails.application.reloader.to_prepare do
  ActiveRecord::Type.register(:geolocation_array, Geolocation::ArrayType)
  ActiveModel::Type.register(:geolocation_array, Geolocation::ArrayType)
end
