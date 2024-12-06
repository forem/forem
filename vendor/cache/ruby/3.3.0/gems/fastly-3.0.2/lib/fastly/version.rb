class Fastly
  # An iteration of your configuration
  class Version < Base
    attr_accessor :service_id, :number, :name, :active, :staging, :testing, :deployed, :comment, :locked

    ##
    # :attr: service_id
    # The id of the service this belongs to.

    ##
    # :attr: number
    # The generation of this version

    ##
    # :attr: name
    #
    # The name of this version.

    ##
    # :attr: active
    #
    # Whether this version is active or not.

    ##
    # :attr: locked
    #
    # Whether this version is locked or not.

    ##
    # :attr: staging
    #
    # Whether this version is in staging or not.

    ##
    # :attr: testing
    #
    # Whether this version is in testing or not.
    #

    ##
    # :attr: deployed
    #
    # Whether this version is deployed or not.
    #

    ##
    # :attr: comment
    #
    # a free form comment field

    # Is this Version locked
    def locked?
      true == @locked
    end

    # Get the Service object this Version belongs to
    def service
      fetcher.get(Service, service_id)
    end

    # Get the Settings object for this Version
    def settings
      fetcher.get_settings(service_id, number)
    end

    # Is version active?
    def active?
      true == @active
    end

    # Activate this version
    def activate!
      hash = fetcher.client.put("#{Version.put_path(self)}/activate")
      !hash.nil?
    end

    # Deactivate this version
    def deactivate!
      hash = fetcher.client.put("#{Version.put_path(self)}/deactivate")
      !hash.nil?
    end

    # Clone this Version
    def clone
      hash = fetcher.client.put("#{Version.put_path(self)}/clone")
      return nil if hash.nil?
      Version.new(hash, fetcher)
    end

    # Create an entirely new version, not cloned from the previous one.
    def self.create_new(fetcher, opts)
      hash = fetcher.client.post(Version.post_path(opts))
      return nil if hash.nil?

      Version.new(hash, fetcher)
    end

    # Get the generated VCL object for this Version (which must have been activated first)
    #
    # Won't return the content of the VCL unless you pass in
    #    :include_content => true
    # in the opts
    def generated_vcl(opts = {})
      hash = fetcher.client.get("#{Version.put_path(self)}/generated_vcl", opts)
      opts = {
        'content'    => hash['vcl'] || hash['content'],
        'name'       => hash['md5'],
        'version'    => hash['version'],
        'service_id' => hash['service']
      }

      VCL.new(opts, fetcher)
    end

    # Upload a VCL file for this Version
    def upload_vcl(name, content)
      hash = fetcher.client.post("#{Version.put_path(self)}/vcl", name: name, content: content)
      return nil if hash.nil?
      VCL.new(hash, fetcher)
    end

    # Upload a VCL file for this Version and set as the main VCL
    def upload_main_vcl(name, contents)
      upload_vcl(name, contents).set_main!
    end

    # Get the named VCL for this version
    #
    # Won't return the content of the VCL unless you pass in
    #    :include_content => true
    # in the opts
    def vcl(name, opts = {})
      fetcher.get_vcl(service_id, number, name, opts)
    end

    # Delete a VCL file for this Version
    def delete_vcl(name)
      hash = fetcher.client.delete("#{Version.put_path(self)}/vcl/#{name}")
      hash.nil? ? nil : hash
    end

    def dictionaries
      fetcher.list_dictionaries(:service_id => service_id, :version => number)
    end

    # Validate this Version
    def validate
      hash = fetcher.client.get("#{Version.put_path(self)}/validate")

      valid = ("ok" == hash["status"])
      message = hash['msg']

      [valid, message]
    end

    def self.get_path(service, number)
      "/service/#{service}/version/#{number}"
    end

    def self.post_path(opts = {})
      "/service/#{opts[:service_id]}/version"
    end

    def self.put_path(obj)
      get_path(obj.service_id, obj.number)
    end

    def self.delete_path(obj)
      put_path(obj)
    end
  end
end
