require 'openssl'
require 'time'
require 'base64'

class AwsCfSigner

  attr_reader :key_pair_id

  def initialize(key_or_pem_path, key_pair_id = nil)
    if key_or_pem_path =~ /BEGIN RSA PRIVATE KEY/
      @key = OpenSSL::PKey::RSA.new(key_or_pem_path)
      @key_pair_id = key_pair_id or raise ArgumentError, "key_pair_id could not be inferred - please pass in explicitly"
    else
      @pem_path    = key_or_pem_path
      @key         = OpenSSL::PKey::RSA.new(File.readlines(@pem_path).join(""))
      @key_pair_id = key_pair_id ? key_pair_id : extract_key_pair_id(@pem_path)
      unless @key_pair_id
        raise ArgumentError.new("key_pair_id couldn't be inferred from #{@pem_path} - please pass in explicitly")
      end
    end
  end

  def sign(url_to_sign, policy_options = {})
    separator = url_to_sign =~ /\?/ ? '&' : '?'
    if policy_options[:policy_file]
      policy = IO.read(policy_options[:policy_file])
      "#{url_to_sign}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
    else
      raise ArgumentError.new("'ending' argument is required") if policy_options[:ending].nil?
      if policy_options.keys == [:ending] || policy_options.keys.sort == [:ending, :resource]
        # Canned Policy - shorter URL
        expires_at = epoch_time(policy_options[:ending])
        policy = %({"Statement":[{"Resource":"#{policy_options[:resource] || url_to_sign}","Condition":{"DateLessThan":{"AWS:EpochTime":#{expires_at}}}}]})
        "#{url_to_sign}#{separator}Expires=#{expires_at}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
      else
        # Custom Policy
        resource = policy_options[:resource] || url_to_sign
        policy = generate_custom_policy(resource, policy_options)
        "#{url_to_sign}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
      end
    end
  end

  def generate_custom_policy(resource, options)
    conditions = ["\"DateLessThan\":{\"AWS:EpochTime\":#{epoch_time(options[:ending])}}"]
    conditions << "\"DateGreaterThan\":{\"AWS:EpochTime\":#{epoch_time(options[:starting])}}" if options[:starting]
    conditions << "\"IpAddress\":{\"AWS:SourceIp\":\"#{options[:ip_range] || '0.0.0.0/0'}\""
    %({"Statement":[{"Resource":"#{resource}","Condition":{#{conditions.join(',')}}}}]})
  end

  def epoch_time(timelike)
    case timelike
    when String then Time.parse(timelike).to_i
    when Time   then timelike.to_i
    else raise ArgumentError.new("Invalid argument - String or Time required - #{timelike.class} passed.")
    end
  end

  def encode_policy(policy)
    url_safe(Base64.encode64(policy))
  end

  def create_signature(policy)
    url_safe(Base64.encode64(@key.sign(OpenSSL::Digest::SHA1.new, (policy))))
  end

  def extract_key_pair_id(key_path)
    File.basename(key_path) =~ /^pk-(.*).pem$/ ? $1 : nil
  end

  def url_safe(s)
    s.gsub('+','-').gsub('=','_').gsub('/','~').gsub(/\n/,'').gsub(' ','')
  end

end
