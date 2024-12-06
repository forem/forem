module Fog
  module AWS
    class Storage
      require 'fog/aws/parsers/storage/access_control_list'

      private
        def self.hash_to_acl(acl)
          data =  "<AccessControlPolicy>\n"

          if acl['Owner'] && (acl['Owner']['ID'] || acl['Owner']['DisplayName'])
            data << "  <Owner>\n"
            data << "    <ID>#{acl['Owner']['ID']}</ID>\n" if acl['Owner']['ID']
            data << "    <DisplayName>#{acl['Owner']['DisplayName']}</DisplayName>\n" if acl['Owner']['DisplayName']
            data << "  </Owner>\n"
          end

          grants = [acl['AccessControlList']].flatten.compact

          data << "  <AccessControlList>\n" if grants.any?
          grants.each do |grant|
            data << "    <Grant>\n"
            grantee = grant['Grantee']
            type = case
            when grantee.key?('ID')
              'CanonicalUser'
            when grantee.key?('EmailAddress')
              'AmazonCustomerByEmail'
            when grantee.key?('URI')
              'Group'
            end

            data << "      <Grantee xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:type=\"#{type}\">\n"
            case type
            when 'CanonicalUser'
              data << "        <ID>#{grantee['ID']}</ID>\n" if grantee['ID']
              data << "        <DisplayName>#{grantee['DisplayName']}</DisplayName>\n" if grantee['DisplayName']
            when 'AmazonCustomerByEmail'
              data << "        <EmailAddress>#{grantee['EmailAddress']}</EmailAddress>\n" if grantee['EmailAddress']
            when 'Group'
              data << "        <URI>#{grantee['URI']}</URI>\n" if grantee['URI']
            end
            data << "      </Grantee>\n"
            data << "      <Permission>#{grant['Permission']}</Permission>\n"
            data << "    </Grant>\n"
          end
          data << "  </AccessControlList>\n" if grants.any?

          data << "</AccessControlPolicy>"

          data
        end

        def self.acl_to_hash(acl_xml)
          parser = Fog::Parsers::AWS::Storage::AccessControlList.new
          Nokogiri::XML::SAX::Parser.new(parser).parse(acl_xml)
          parser.response
        end
    end
  end
end
