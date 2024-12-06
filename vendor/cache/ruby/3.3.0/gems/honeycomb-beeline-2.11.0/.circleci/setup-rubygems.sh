mkdir ~/.gem
echo -e "---\r\n:rubygems_api_key: $GEM_HOST_API_KEY" > ~/.gem/credentials
chmod 0600 /home/circleci/.gem/credentials
