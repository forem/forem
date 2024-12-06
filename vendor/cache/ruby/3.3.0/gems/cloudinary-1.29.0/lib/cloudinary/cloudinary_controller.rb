module Cloudinary::CloudinaryController
  protected

  def valid_cloudinary_response?
    received_signature = request.query_parameters[:signature]
    calculated_signature = Cloudinary::Utils.api_sign_request(
      request.query_parameters.select{|key, value| [:public_id, :version].include?(key.to_sym)},
      Cloudinary.config.api_secret)
    return received_signature == calculated_signature
  end
end
