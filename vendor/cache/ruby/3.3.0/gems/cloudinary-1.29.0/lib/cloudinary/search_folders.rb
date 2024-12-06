# The Cloudinary API folders search method allows you fine control on filtering and retrieving information on all the
# folders in your cloud with the help of query expressions in a Lucene-like query language.
class Cloudinary::SearchFolders < Cloudinary::Search
  ENDPOINT = 'folders'
end
