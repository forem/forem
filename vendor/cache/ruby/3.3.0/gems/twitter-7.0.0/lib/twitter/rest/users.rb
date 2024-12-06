require 'twitter/arguments'
require 'twitter/error'
require 'twitter/profile_banner'
require 'twitter/rest/request'
require 'twitter/rest/utils'
require 'twitter/settings'
require 'twitter/user'
require 'twitter/utils'

module Twitter
  module REST
    module Users
      include Twitter::REST::Utils
      include Twitter::Utils
      MAX_USERS_PER_REQUEST = 100

      # Updates the authenticating user's settings.
      # Or, if no options supplied, returns settings (including current trend, geo and sleep time information) for the authenticating user.
      #
      # @see https://dev.twitter.com/rest/reference/post/account/settings
      # @see https://dev.twitter.com/rest/reference/get/account/settings
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Settings]
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :trend_location_woeid The Yahoo! Where On Earth ID to use as the user's default trend location. Global information is available by using 1 as the WOEID. The woeid must be one of the locations returned by {https://dev.twitter.com/rest/reference/get/trends/available GET trends/available}.
      # @option options [Boolean, String, Integer] :sleep_time_enabled When set to true, 't' or 1, will enable sleep time for the user. Sleep time is the time when push or SMS notifications should not be sent to the user.
      # @option options [Integer] :start_sleep_time The hour that sleep time should begin if it is enabled. The value for this parameter should be provided in {http://en.wikipedia.org/wiki/ISO_8601 ISO8601} format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting.
      # @option options [Integer] :end_sleep_time The hour that sleep time should end if it is enabled. The value for this parameter should be provided in {http://en.wikipedia.org/wiki/ISO_8601 ISO8601} format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting.
      # @option options [String] :time_zone The timezone dates and times should be displayed in for the user. The timezone must be one of the {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Rails TimeZone} names.
      # @option options [String] :lang The language which Twitter should render in for this user. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by {https://dev.twitter.com/rest/reference/get/help/languages GET help/languages}.
      # @option options [String] :allow_contributor_request Whether to allow others to include user as contributor. Possible values include 'all' (anyone can include user), 'following' (only followers can include user) or 'none'. Also note that changes to this field require the request also include a current_password value with the user's password to successfully modify this field.
      # @option options [String] :current_password The user's password. This is only required when modifying the allow_contributor_request field.
      def settings(options = {})
        request_method = options.size.zero? ? :get : :post
        response = perform_request(request_method.to_sym, '/1.1/account/settings.json', options)
        # https://dev.twitter.com/issues/59
        response[:trend_location] = response.fetch(:trend_location, []).first
        Twitter::Settings.new(response)
      end

      # Returns the requesting user if authentication was successful, otherwise raises {Twitter::Error::Unauthorized}
      #
      # @see https://dev.twitter.com/rest/reference/get/account/verify_credentials
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The authenticated user.
      # @param options [Hash] A customizable set of options.
      # @option options [Boolean, String, Integer] :skip_status Do not include user's Tweets when set to true, 't' or 1.
      def verify_credentials(options = {})
        perform_get_with_object('/1.1/account/verify_credentials.json', options, Twitter::User)
      end

      # Sets which device Twitter delivers updates to for the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/account/update_delivery_device
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The authenticated user.
      # @param device [String] Must be one of: 'sms', 'none'.
      # @param options [Hash] A customizable set of options.
      def update_delivery_device(device, options = {})
        perform_post_with_object('/1.1/account/update_delivery_device.json', options.merge(device: device), Twitter::User)
      end

      # Sets values that users are able to set under the "Account" tab of their settings page
      #
      # @see https://dev.twitter.com/rest/reference/post/account/update_profile
      # @note Only the options specified will be updated.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The authenticated user.
      # @param options [Hash] A customizable set of options.
      # @option options [String] :name Full name associated with the profile. Maximum of 20 characters.
      # @option options [String] :url URL associated with the profile. Will be prepended with "http://" if not present. Maximum of 100 characters.
      # @option options [String] :location The city or country describing where the user of the account is located. The contents are not normalized or geocoded in any way. Maximum of 30 characters.
      # @option options [String] :description A description of the user owning the account. Maximum of 160 characters.
      # @option options [String] :profile_link_color A hex value of the color scheme used for links on user's profile page. Must be a valid hexadecimal value, and may be either three or six characters
      def update_profile(options = {})
        perform_post_with_object('/1.1/account/update_profile.json', options, Twitter::User)
      end

      # Updates the authenticating user's profile background image
      #
      # @see https://dev.twitter.com/rest/reference/post/account/update_profile_background_image
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The authenticated user.
      # @param image [File] The background image for the profile, base64-encoded. Must be a valid GIF, JPG, or PNG image of less than 800 kilobytes in size. Images with width larger than 2048 pixels will be forcibly scaled down. The image must be provided as raw multipart data, not a URL.
      # @param options [Hash] A customizable set of options.
      # @option options [Boolean] :tile Whether or not to tile the background image. If set to true the background image will be displayed tiled. The image will not be tiled otherwise.
      def update_profile_background_image(image, options = {})
        post_profile_image('/1.1/account/update_profile_background_image.json', image, options)
      end

      # Updates the authenticating user's profile image
      #
      # @see https://dev.twitter.com/rest/reference/post/account/update_profile_image
      # @note Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image.
      # @note This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/show.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The authenticated user.
      # @param image [File] The avatar image for the profile, base64-encoded. Must be a valid GIF, JPG, or PNG image of less than 700 kilobytes in size. Images with width larger than 500 pixels will be scaled down. Animated GIFs will be converted to a static GIF of the first frame, removing the animation.
      # @param options [Hash] A customizable set of options.
      def update_profile_image(image, options = {})
        post_profile_image('/1.1/account/update_profile_image.json', image, options)
      end

      # Returns an array of user objects that the authenticating user is blocking
      #
      # @see https://dev.twitter.com/rest/reference/get/blocks/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] User objects that the authenticating user is blocking.
      # @param options [Hash] A customizable set of options.
      # @option options [Boolean, String, Integer] :skip_status Do not include user's Tweets when set to true, 't' or 1.
      def blocked(options = {})
        perform_get_with_cursor('/1.1/blocks/list.json', options, :users, Twitter::User)
      end

      # Returns an array of numeric user IDs the authenticating user is blocking
      #
      # @see https://dev.twitter.com/rest/reference/get/blocks/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor] Numeric user IDs the authenticating user is blocking.
      # @overload blocked_ids(options = {})
      #   @param options [Hash] A customizable set of options.
      def blocked_ids(*args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop)
        perform_get_with_cursor('/1.1/blocks/ids.json', arguments.options, :ids)
      end

      # Returns true if the authenticating user is blocking a target user
      #
      # @see https://dev.twitter.com/rest/reference/get/blocks/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Boolean] true if the authenticating user is blocking the target user, otherwise false.
      # @param user [Integer, String, URI, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @param options [Hash] A customizable set of options.
      def block?(user, options = {})
        user_id =
          case user
          when Integer                       then user
          when String, URI, Addressable::URI then user(user).id
          when Twitter::User                 then user.id
          end
        blocked_ids(options).collect(&:to_i).include?(user_id)
      end

      # Blocks the users specified by the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/blocks/create
      # @note Destroys a friendship to the blocked user if it exists.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The blocked users.
      # @overload block(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload block(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def block(*args)
        parallel_users_from_response(:post, '/1.1/blocks/create.json', args)
      end

      # Un-blocks the users specified by the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/blocks/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The un-blocked users.
      # @overload unblock(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload unblock(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def unblock(*args)
        parallel_users_from_response(:post, '/1.1/blocks/destroy.json', args)
      end

      # Returns extended information for up to 100 users
      #
      # @see https://dev.twitter.com/rest/reference/get/users/lookup
      # @rate_limited Yes
      # @authentication Required
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The requested users.
      # @overload users(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload users(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def users(*args)
        arguments = Twitter::Arguments.new(args)
        flat_pmap(arguments.each_slice(MAX_USERS_PER_REQUEST)) do |users|
          perform_get_with_objects('/1.1/users/lookup.json', merge_users(arguments.options, users), Twitter::User)
        end
      end

      # @see https://dev.twitter.com/rest/reference/get/users/show
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::User] The requested user.
      # @overload user(options = {})
      #   Returns extended information for the authenticated user
      #
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include user's Tweets when set to true, 't' or 1.
      # @overload user(user, options = {})
      #   Returns extended information for a given user
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include user's Tweets when set to true, 't' or 1.
      def user(*args)
        arguments = Twitter::Arguments.new(args)
        if arguments.last || user_id?
          merge_user!(arguments.options, arguments.pop || user_id)
          perform_get_with_object('/1.1/users/show.json', arguments.options, Twitter::User)
        else
          verify_credentials(arguments.options)
        end
      end

      # Returns true if the specified user exists
      #
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Boolean] true if the user exists, otherwise false.
      # @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      def user?(user, options = {})
        options = options.dup
        merge_user!(options, user)
        perform_get('/1.1/users/show.json', options)
        true
      rescue Twitter::Error::NotFound
        false
      end

      # Returns users that match the given query
      #
      # @see https://dev.twitter.com/rest/reference/get/users/search
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>]
      # @param query [String] The search query to run against people search.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :count The number of people to retrieve. Maxiumum of 20 allowed per page.
      # @option options [Integer] :page Specifies the page of results to retrieve.
      def user_search(query, options = {})
        options = options.dup
        perform_get_with_objects('/1.1/users/search.json', options.merge(q: query), Twitter::User)
      end

      # Returns an array of users that the specified user can contribute to
      #
      # @see https://dev.twitter.com/rest/reference/get/users/contributees
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>]
      # @overload contributees(options = {})
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      # @overload contributees(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      def contributees(*args)
        users_from_response(:get, '/1.1/users/contributees.json', args)
      end

      # Returns an array of users who can contribute to the specified account
      #
      # @see https://dev.twitter.com/rest/reference/get/users/contributors
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>]
      # @overload contributors(options = {})
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      # @overload contributors(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      def contributors(*args)
        users_from_response(:get, '/1.1/users/contributors.json', args)
      end

      # Removes the authenticating user's profile banner image
      #
      # @see https://dev.twitter.com/rest/reference/post/account/remove_profile_banner
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [nil]
      # @param options [Hash] A customizable set of options.
      def remove_profile_banner(options = {})
        perform_post('/1.1/account/remove_profile_banner.json', options)
        true
      end

      # Updates the authenticating user's profile banner image
      #
      # @see https://dev.twitter.com/rest/reference/post/account/update_profile_banner
      # @note Uploads a profile banner on behalf of the authenticating user. For best results, upload an <5MB image that is exactly 1252px by 626px. Images will be resized for a number of display options. Users with an uploaded profile banner will have a profile_banner_url node in their Users objects. More information about sizing variations can be found in User Profile Images and Banners.
      # @note Profile banner images are processed asynchronously. The profile_banner_url and its variant sizes will not necessary be available directly after upload.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::BadRequest] Error raised when either an image was not provided or the image data could not be processed.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @raise [Twitter::Error::UnprocessableEntity] Error raised when the image could not be resized or is too large.
      # @return [nil]
      # @param banner [File] The Base64-encoded or raw image data being uploaded as the user's new profile banner.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :width The width of the preferred section of the image being uploaded in pixels. Use with height, offset_left, and offset_top to select the desired region of the image to use.
      # @option options [Integer] :height The height of the preferred section of the image being uploaded in pixels. Use with width, offset_left, and offset_top to select the desired region of the image to use.
      # @option options [Integer] :offset_left The number of pixels by which to offset the uploaded image from the left. Use with height, width, and offset_top to select the desired region of the image to use.
      # @option options [Integer] :offset_top The number of pixels by which to offset the uploaded image from the top. Use with height, width, and offset_left to select the desired region of the image to use.
      def update_profile_banner(banner, options = {})
        perform_post('/1.1/account/update_profile_banner.json', options.merge(banner: banner))
        true
      end

      # Returns the available size variations of the specified user's profile banner.
      #
      # @see https://dev.twitter.com/rest/reference/get/users/profile_banner
      # @note If the user has not uploaded a profile banner, a HTTP 404 will be served instead.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::ProfileBanner]
      # @overload profile_banner(options = {})
      # @overload profile_banner(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      def profile_banner(*args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop || user_id) unless arguments.options[:user_id] || arguments.options[:screen_name]
        perform_get_with_object('/1.1/users/profile_banner.json', arguments.options, Twitter::ProfileBanner)
      end

      # Mutes the users specified by the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/mutes/users/create
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The muted users.
      # @overload mute(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload mute(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def mute(*args)
        parallel_users_from_response(:post, '/1.1/mutes/users/create.json', args)
      end

      # Un-mutes the user specified by the authenticating user.
      #
      # @see https://dev.twitter.com/rest/reference/post/mutes/users/destroy
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The un-muted users.
      # @overload unmute(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload unmute(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def unmute(*args)
        parallel_users_from_response(:post, '/1.1/mutes/users/destroy.json', args)
      end

      # Returns an array of user objects that the authenticating user is muting
      #
      # @see https://dev.twitter.com/rest/reference/get/mutes/users/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] User objects that the authenticating user is muting.
      # @param options [Hash] A customizable set of options.
      # @option options [Boolean, String, Integer] :skip_status Do not include user's Tweets when set to true, 't' or 1.
      def muted(options = {})
        perform_get_with_cursor('/1.1/mutes/users/list.json', options, :users, Twitter::User)
      end

      # Returns an array of numeric user IDs the authenticating user is muting
      #
      # @see https://dev.twitter.com/rest/reference/get/mutes/users/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor] Numeric user IDs the authenticating user is muting
      # @overload muted_ids(options = {})
      #   @param options [Hash] A customizable set of options.
      def muted_ids(*args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop)
        perform_get_with_cursor('/1.1/mutes/users/ids.json', arguments.options, :ids)
      end

    private

      def post_profile_image(path, image, options)
        response = Twitter::REST::Request.new(self, :multipart_post, path, options.merge(key: :image, file: image)).perform
        Twitter::User.new(response)
      end
    end
  end
end
