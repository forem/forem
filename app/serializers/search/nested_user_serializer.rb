module Search
  class NestedUserSerializer
    include FastJsonapi::ObjectSerializer

    attributes :username, :name, :id, :profile_image_90, :pro
  end
end
