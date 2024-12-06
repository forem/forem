require "oauth/signature/base"

module OAuth::Signature
  class PLAINTEXT < Base
    implements "plaintext"

    def signature
      signature_base_string
    end

    def ==(cmp_signature)
      signature.to_s == cmp_signature.to_s
    end

    def signature_base_string
      secret
    end

    def body_hash
      nil
    end

    private

    def secret
      super
    end
  end
end
