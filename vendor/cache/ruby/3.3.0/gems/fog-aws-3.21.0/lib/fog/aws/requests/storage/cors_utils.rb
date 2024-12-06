module Fog
  module AWS
    class Storage
      require 'fog/aws/parsers/storage/cors_configuration'

      private

        def self.hash_to_cors(cors)
          data =  "<CORSConfiguration>\n"

          [cors['CORSConfiguration']].flatten.compact.each do |rule|
            data << "  <CORSRule>\n"

            ['ID', 'MaxAgeSeconds'].each do |key|
              data << "    <#{key}>#{rule[key]}</#{key}>\n" if rule[key]
            end

            ['AllowedOrigin', 'AllowedMethod', 'AllowedHeader', 'ExposeHeader'].each do |key|
              [rule[key]].flatten.compact.each do |value|
                data << "    <#{key}>#{value}</#{key}>\n"
              end
            end

            data << "  </CORSRule>\n"
          end

          data << "</CORSConfiguration>"

          data
        end

        def self.cors_to_hash(cors_xml)
          parser = Fog::Parsers::AWS::Storage::CorsConfiguration.new
          Nokogiri::XML::SAX::Parser.new(parser).parse(cors_xml)
          parser.response
        end
    end
  end
end
