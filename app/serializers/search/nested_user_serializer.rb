module Search
  class NestedUserSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id, :name, :pro, :profile_image_90, :username
  end
end
