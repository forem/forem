class Cloudinary::Api
  extend Cloudinary::BaseApi

  # Tests the reachability of the Cloudinary API.
  #
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response] The current status of the Cloudinary servers
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#ping
  def self.ping(options={})
    call_api(:get, "ping", {}, options)
  end

  # Gets cloud usage details.
  #
  # Returns a report detailing your current Cloudinary cloud usage details, including
  # storage, bandwidth, requests, number of assets, and add-on usage.
  # Note that numbers are updated periodically.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#usage Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api:Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#usage
  def self.usage(options={})
    uri = 'usage'
    date = options[:date]

    uri += "/#{Cloudinary::Utils.to_usage_api_date_format(date)}" unless date.nil?

    call_api(:get, uri, {}, options)
  end

  # Lists all uploaded assets filtered by any specified options.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources
  def self.resource_types(options={})
    call_api(:get, "resources", {}, options)
  end

  # Lists all uploaded assets filtered by any specified options.
  #
  # see https://cloudinary.com/documentation/admin_api#get_resources Get all images
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources
  def self.resources(options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type]
    uri           = "resources/#{resource_type}"
    uri           += "/#{type}" unless type.blank?
    call_api(:get, uri, list_resources_params(options).merge(only(options, :prefix, :start_at)), options)
  end

  # Lists assets with the specified tag.
  #
  # This method does not return matching deleted assets, even if they have been backed up.
  #
  # @param [String] tag     The tag value.
  # @param [Hash]   options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources_by_tag Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources_by_tag
  def self.resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/tags/#{tag}"
    call_api(:get, uri, list_resources_params(options), options)
  end

  # Lists assets currently in the specified moderation queue and status.
  #
  # @param [String] kind    Type of image moderation queue to list.
  #                         Valid values:  "manual", "webpurify", "aws_rek", or "metascan".
  # @param [String] status  Only assets with this moderation status will be returned.
  #                         Valid values: "pending", "approved", "rejected".
  # @param [Hash]   options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources_in_moderation_queues Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources_in_moderation_queues
  def self.resources_by_moderation(kind, status, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/moderations/#{kind}/#{status}"
    call_api(:get, uri, list_resources_params(options), options)
  end

  # Lists assets with the specified contextual metadata.
  #
  # This method does not return matching deleted assets, even if they have been backed up.
  #
  # @param [String] key     Only assets with this context key are returned.
  # @param [String] value   Only assets with this context value for the specified context key are returned.
  #                         If this parameter is not provided, all assets with the specified context key are returned,
  #                         regardless of the key value.
  # @param [Hash]   options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources_by_context Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources_by_context
  def self.resources_by_context(key, value=nil, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/context"
    call_api(:get, uri, list_resources_params(options, :key => key, :value => value), options)
  end

  # Lists assets with the specified public IDs.
  #
  # @param [String|Array] public_ids The requested public_ids (up to 100).
  # @param [Hash]          options    The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources
  def self.resources_by_ids(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:get, uri, resources_params(options, :public_ids => public_ids), options)
  end

  # Lists assets with the specified asset IDs.
  #
  # @param [Object] asset_ids The requested asset IDs.
  # @param [Hash]   options   The optional parameters. See the
  # <a href=https://cloudinary.com/documentation/admin_api#get_resources target="_blank"> Admin API</a> documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_resources
  def self.resources_by_asset_ids(asset_ids, options={})
    uri = "resources/by_asset_ids"
    call_api(:get, uri, resources_params(options, :asset_ids => asset_ids), options)
  end

  # Returns all assets stored directly in a specified asset folder, regardless of the public ID paths of those assets.
  #
  # @param [String] asset_folder The requested asset folder.
  # @param [Hash]   options      The optional parameters. See the
  # <a href=https://cloudinary.com/documentation/dynamic_folders#new_admin_api_endpoints target="_blank"> Admin API</a> documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/dynamic_folders#new_admin_api_endpoints
  def self.resources_by_asset_folder(asset_folder, options={})
    uri = "resources/by_asset_folder"
    call_api(:get, uri, list_resources_params(options, :asset_folder => asset_folder), options)
  end

  # Find images based on their visual content.
  #
  # @param [Hash]   options      The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.visual_search(options = {})
    uri    = "resources/visual_search"
    params = only(options, :image_url, :image_asset_id, :text, :image_file)
    params[:image_file] = Cloudinary::Utils.handle_file_param(params[:image_file]) if params.has_key?(:image_file)
    call_api(:post, uri, params, options)
  end

  # Returns the details of the specified asset and all its derived assets.
  #
  # Note that if you only need details about the original asset,
  # you can also use the Uploader::upload or Uploader::explicit methods, which return the same information and
  # are not rate limited.
  #
  # @param [String] public_id The public ID of the asset.
  # @param [Hash]   options   The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_resource Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_resource
  def self.resource(public_id, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}/#{public_id}"
    call_api(:get, uri, prepare_resource_details_params(options), options)
  end

  # Returns the details of the specified asset and all its derived assets by asset id.
  #
  # Note that if you only need details about the original asset,
  # you can also use the Uploader::upload or Uploader::explicit methods, which return the same information and
  # are not rate limited.
  #
  # @param [String] asset_id The Asset ID of the asset.
  # @param [Hash]   options  The optional parameters. See the <a href=https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_resource target="_blank"> Admin API</a> documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_resource
  def self.resource_by_asset_id(asset_id, options={})
    uri    = "resources/#{asset_id}"
    call_api(:get, uri, prepare_resource_details_params(options), options)
  end

  # Reverts to the latest backed up version of the specified deleted assets.
  #
  # @param [String|Array] public_ids The public IDs of the backed up assets to restore. They can be existing or
  #   deleted assets.
  # @param [Hash]          options    The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#restore_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#restore_resources
  def self.restore(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}/restore"
    call_api(:post, uri, { :public_ids => public_ids, :versions => options[:versions] }, options)
  end

  # Updates details of an existing asset.
  #
  # Update one or more of the attributes associated with a specified asset. Note that you can also update
  # most attributes of an existing asset using the Uploader::explicit method, which is not rate limited.
  #
  # @param [String|Array] public_id The public ID of the asset to update.
  # @param [Hash]          options   The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#update_details_of_an_existing_resource Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_details_of_an_existing_resource
  def self.update(public_id, options={})
    resource_type  = options[:resource_type] || "image"
    type           = options[:type] || "upload"
    uri            = "resources/#{resource_type}/#{type}/#{public_id}"
    update_options = {
      :access_control     => Cloudinary::Utils.json_array_param(options[:access_control]),
      :asset_folder       => options[:asset_folder],
      :auto_tagging       => options[:auto_tagging] && options[:auto_tagging].to_f,
      :background_removal => options[:background_removal],
      :categorization     => options[:categorization],
      :context            => Cloudinary::Utils.encode_context(options[:context]),
      :custom_coordinates => Cloudinary::Utils.encode_double_array(options[:custom_coordinates]),
      :detection          => options[:detection],
      :display_name       => options[:display_name],
      :face_coordinates   => Cloudinary::Utils.encode_double_array(options[:face_coordinates]),
      :metadata           => Cloudinary::Utils.encode_context(options[:metadata]),
      :moderation_status  => options[:moderation_status],
      :notification_url   => options[:notification_url],
      :quality_override   => options[:quality_override],
      :ocr                => options[:ocr],
      :raw_convert        => options[:raw_convert],
      :similarity_search  => options[:similarity_search],
      :tags               => options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(","),
      :clear_invalid      => Cloudinary::Utils.as_safe_bool(options[:clear_invalid]),
      :unique_display_name=> options[:unique_display_name]
    }
    call_api(:post, uri, update_options, options)
  end

  # Deletes the specified assets.
  #
  # @param [String|Array] public_ids The public IDs of the assets to delete (up to 100).
  # @param [Hash]          options    The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#sdelete_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_resources
  def self.delete_resources(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :public_ids => public_ids ), options)
  end

  # Deletes assets by prefix.
  #
  # Delete up to 1000 original assets, along with their derived assets, where the public ID starts with the
  # specified prefix.
  #
  # @param [String] prefix  The Public ID prefix.
  # @param [Hash]   options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#delete_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_resources
  def self.delete_resources_by_prefix(prefix, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :prefix => prefix), options)
  end

  # Deletes all assets of the specified asset and delivery type, including their derived assets.
  #
  # Supports deleting up to a maximum of 1000 original assets in a single call.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#delete_resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # https://cloudinary.com/documentation/admin_api#delete_resources
  def self.delete_all_resources(options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :all => true ), options)
  end

  # Deletes assets with the specified tag, including their derived assets.
  #
  # Supports deleting up to a maximum of 1000 original assets in a single call.
  #
  # @param [String] tag     The tag value of the assets to delete.
  # @param [Hash]   options The optional parameters. See the
  # {https://cloudinary.com/documentation/admin_api#delete_resources_by_tags Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_resources_by_tags
  def self.delete_resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/tags/#{tag}"
    call_api(:delete, uri, delete_resource_params(options), options)
  end

  # Deletes the specified derived assets by derived asset ID.
  #
  # The derived asset IDs for a particular original asset are returned when calling the {.resource} method to
  # return the details of a single asset.
  #
  # @param [String|Array] derived_resource_ids The derived asset IDs (up to 100 ids).
  # @param [Hash]          options              The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api##delete_resources
  def self.delete_derived_resources(derived_resource_ids, options={})
    uri = "derived_resources"
    call_api(:delete, uri, { :derived_resource_ids => derived_resource_ids }, options)
  end

  # Deletes derived assets identified by transformation and public_ids.
  #
  # @param [String|Array]      public_ids      The public IDs for which you want to delete derived assets.
  # @param [String|Array|Hash] transformations The transformation(s) associated with the derived assets to delete.
  # @param [Hash]              options         The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#resources Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.delete_derived_by_transformation(public_ids, transformations, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    params = {:public_ids => public_ids}.merge(only(options, :invalidate))
    params[:keep_original] = true
    params[:transformations] = Cloudinary::Utils.build_eager(transformations)
    call_api(:delete, uri, params, options)
  end

  # Relates an asset to other assets by public IDs.
  #
  # @param [String]            public_id        The public ID of the asset.
  # @param [String|Array]      assets_to_relate The array of up to 10 fully_qualified_public_ids given as
  #                                             resource_type/type/public_id.
  # @param [Hash]              options          The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#add_related_assets Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.add_related_assets(public_id, assets_to_relate, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/related_assets/#{resource_type}/#{type}/#{public_id}"
    params = {:assets_to_relate => Cloudinary::Utils.build_array(assets_to_relate)}
    call_api(:post, uri, params, options)
  end

  # Relates an asset to other assets by asset IDs.
  #
  # @param [String]            asset_id         The asset ID of the asset to update.
  # @param [String|Array]      assets_to_relate The array of up to 10 asset IDs.
  # @param [Hash]              options          The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#add_related_assets_by_asset_id Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.add_related_assets_by_asset_ids(asset_id, assets_to_relate, options={})
    uri           = "resources/related_assets/#{asset_id}"
    params = {:assets_to_relate => Cloudinary::Utils.build_array(assets_to_relate)}
    call_api(:post, uri, params, options)
  end

  # Unrelates an asset from other assets by public IDs.
  #
  # @param [String]            public_id          The public ID of the asset.
  # @param [String|Array]      assets_to_unrelate The array of up to 10 fully_qualified_public_ids given as
  #                                               resource_type/type/public_id.
  # @param [Hash]              options            The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#delete_related_assets Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.delete_related_assets(public_id, assets_to_unrelate, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/related_assets/#{resource_type}/#{type}/#{public_id}"
    params = {:assets_to_unrelate => Cloudinary::Utils.build_array(assets_to_unrelate)}
    call_api(:delete, uri, params, options)
  end

  # Unrelates an asset from other assets by asset IDs.
  #
  # @param [String]            asset_id           The asset ID of the asset to update.
  # @param [String|Array]      assets_to_unrelate The array of up to 10 asset IDs.
  # @param [Hash]              options            The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#delete_related_assets_by_asset_id Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.delete_related_assets_by_asset_ids(asset_id, assets_to_unrelate, options={})
    uri           = "resources/related_assets/#{asset_id}"
    params = {:assets_to_unrelate => Cloudinary::Utils.build_array(assets_to_unrelate)}
    call_api(:delete, uri, params, options)
  end

  # Lists all the tags currently used for a specified asset type.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_tags Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_tags
  def self.tags(options={})
    resource_type = options[:resource_type] || "image"
    uri           = "tags/#{resource_type}"
    call_api(:get, uri, only(options, :next_cursor, :max_results, :prefix), options)
  end

  # Lists stored transformations.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_transformations Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_transformations
  def self.transformations(options={})
    call_api(:get, "transformations", only(options, :named, :next_cursor, :max_results), options)
  end

  # Returns the details of a single transformation.
  #
  # @param [String|Array] transformation The transformation. Can be either a string or an array of parameters.
  #                                      For example: "w_150,h_100,c_fill" or array("width" => 150, "height" =>
  #                                      100,"crop" => "fill").
  # @param [Hash]         options        The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_transformation_details Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_transformation_details
  def self.transformation(transformation, options={})
    params                  = only(options, :next_cursor, :max_results)
    params[:transformation] = Cloudinary::Utils.build_eager(transformation)
    call_api(:get, "transformations", params, options)
  end

  # Deletes the specified stored transformation.
  #
  # Deleting a transformation also deletes all the stored derived assets based on this transformation (up to 1000).
  # The method returns an error if there are more than 1000 derived assets based on this transformation.
  #
  # @param [String|Hash] transformation The transformation to delete. Can be either a string or an array of
  #                                     parameters. For example:
  #                                     "w_150,h_100,c_fill" or !{"width" => 150, "height" => 100,"crop" => "fill"}.
  # @param [Hash]         options       The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#delete_transformation Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_transformation
  def self.delete_transformation(transformation, options={})
    call_api(:delete, "transformations", {:transformation => Cloudinary::Utils.build_eager(transformation)}, options)
  end

  # Updates the specified transformation.
  #
  # @param [String|Hash] transformation The transformation. Can be either a string or an array of parameters.
  #                                     For example: "w_150,h_100,c_fill" or !{"width" => 150, "height" =>
  #                                     100,"crop" => "fill"}.
  # @param [Hash]        updates        The update parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#update_transformation Admin API} documentation.
  # @param [Hash]        options        The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_transformation
  def self.update_transformation(transformation, updates, options={})
    params                  = only(updates, :allowed_for_strict)
    params[:unsafe_update]  = Cloudinary::Utils.build_eager(updates[:unsafe_update]) if updates[:unsafe_update]
    params[:transformation] = Cloudinary::Utils.build_eager(transformation)
    call_api(:put, "transformations", params, options)
  end

  # Creates a named transformation.
  #
  # @param [String]      name       The name of the transformation.
  # @param [String|Hash] definition The transformation. Can be a string or a hash. For example:
  #                                 "w_150,h_100,c_fill" or !{"width" => 150, "height" => 100, "crop" => "fill"}.
  # @param [Hash]        options    The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_named_transformation
  def self.create_transformation(name, definition, options={})
    params = {
      :name => name,
      :transformation => Cloudinary::Utils.build_eager(definition)
    }

    call_api(:post, "transformations", params, options)
  end

  # Lists existing upload presets.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_upload_presets Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_upload_presets
  def self.upload_presets(options={})
    call_api(:get, "upload_presets", only(options, :next_cursor, :max_results), options)
  end

  # Retrieves the details of the specified upload preset.
  #
  # @param [String] name The name of the upload preset.
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_upload_preset Admin API}
  #   documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_upload_preset
  def self.upload_preset(name, options={})
    call_api(:get, "upload_presets/#{name}", only(options, :max_results), options)
  end

  # Deletes the specified upload preset.
  #
  # @param [String] The name of the upload preset to delete.
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_an_upload_preset
  def self.delete_upload_preset(name, options={})
    call_api(:delete, "upload_presets/#{name}", {}, options)
  end

  # Updates the specified upload preset.
  #
  # @param [String] name The name of the upload preset.
  # @param [Hash] options The optional parameters. See the
  # {https://cloudinary.com/documentation/admin_api#update_an_upload_preset Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_an_upload_preset
  def self.update_upload_preset(name, options={})
    params = Cloudinary::Uploader.build_upload_params(options)
    call_api(:put, "upload_presets/#{name}", params.merge(only(options, :unsigned, :disallow_public_id, :live)), options)
  end

  # Creates a new upload preset.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#create_an_upload_preset Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_an_upload_preset
  def self.create_upload_preset(options={})
    params = Cloudinary::Uploader.build_upload_params(options)
    call_api(:post, "upload_presets", params.merge(only(options, :name, :unsigned, :disallow_public_id, :live)), options)
  end

  # Lists all root folders.
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_root_folders Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_root_folders
  def self.root_folders(options={})
    params = only(options, :max_results, :next_cursor)
    call_api(:get, "folders", params, options)
  end

  # Lists sub-folders.
  #
  # Returns the name and path of all the sub-folders of a specified parent folder. Limited to 2000 results.
  #
  # @param [String] of_folder_path The parent folder.
  # @param [Hash]   options        The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_subfolders Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_subfolders
  def self.subfolders(of_folder_path, options={})
    params = only(options, :max_results, :next_cursor)
    call_api(:get, "folders/#{of_folder_path}", params, options)
  end

  # Deletes an empty folder.
  #
  # The specified folder cannot contain any assets, but can have empty descendant sub-folders.
  #
  # @param [String] path    The full path of the empty folder to delete.
  # @param [Hash]   options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_folder
  def self.delete_folder(path, options={})
    call_api(:delete, "folders/#{path}", {}, options)
  end

  # Creates a new empty folder.
  #
  # @param [String] folder_name The full path of the new folder to create.
  # @param [Hash]   options     The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_folder
  def self.create_folder(folder_name, options={})
    call_api(:post, "folders/#{folder_name}", {}, options)
  end

  # Lists upload mappings by folder and its mapped template (URL).
  #
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#get_upload_mapping Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_upload_mappings
  def self.upload_mappings(options={})
    params = only(options, :next_cursor, :max_results)
    call_api(:get, :upload_mappings, params, options)
  end

  # Returns the details of the specified upload mapping.
  #
  # Retrieve the mapped template (URL) of a specified upload mapping folder.
  #
  # @param [String] name    The name of the upload mapping folder.
  # @param [Hash]   options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_upload_mapping
  def self.upload_mapping(name=nil, options={})
    call_api(:get, 'upload_mappings', { :folder => name }, options)
  end

  # Deletes an upload mapping.
  #
  # @param [String] name    The name of the upload mapping folder to delete.
  # @param [Hash]   options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_an_upload_mapping
  def self.delete_upload_mapping(name, options={})
    call_api(:delete, 'upload_mappings', { :folder => name }, options)
  end

  # Updates an existing upload mapping with a new template (URL).
  #
  # @param [String] name The name of the upload mapping folder to remap.
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#update_an_upload_mapping Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_an_upload_mapping
  def self.update_upload_mapping(name, options={})
    params          = only(options, :template)
    params[:folder] = name
    call_api(:put, 'upload_mappings', params, options)
  end

  # Creates a new upload mapping.
  #
  # @param [String] name The name of the folder to map.
  # @param [Hash] options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#create_an_upload_mapping Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_an_upload_mapping
  def self.create_upload_mapping(name, options={})
    params          = only(options, :template)
    params[:folder] = name
    call_api(:post, 'upload_mappings', params, options)
  end

  # Creates a new, custom streaming profile.
  #
  # @param [String] name    The name to assign to the new streaming profile.
  #                         The name is case-insensitive and can contain alphanumeric characters, underscores (_) and
  #                         hyphens (-). If the name is of a predefined profile, the profile will be modified.
  # @param [Hash]   options The optional parameters. See the
  #   {https://cloudinary.com/documentation/admin_api#create_a_streaming_profile Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_a_streaming_profile
  def self.create_streaming_profile(name, options={})
    params = only(options, :display_name, :representations)
    params[:representations] = params[:representations].map do |r|
      {:transformation => Cloudinary::Utils.generate_transformation_string(r[:transformation])}
    end.to_json
    params[:name] = name
    call_api(:post, 'streaming_profiles', params, options)
  end

  # Lists streaming profiles including built-in and custom profiles.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_adaptive_streaming_profiles
  def self.list_streaming_profiles
    call_api(:get, 'streaming_profiles', {}, {})
  end

  # Deletes or reverts the specified streaming profile.
  #
  # For custom streaming profiles, deletes the specified profile.
  # For built-in streaming profiles, if the built-in profile was modified, reverts the profile to the original
  # settings.
  # For built-in streaming profiles that have not been modified, the Delete method returns an error.
  #
  # @param [String] name    The name of the streaming profile to delete or revert.
  # @param [Hash]   options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_or_revert_the_specified_streaming_profile
  def self.delete_streaming_profile(name, options={})
    call_api(:delete, "streaming_profiles/#{name}", {}, options)
  end

  # Gets details of a single streaming profile by name.
  #
  # @param [String] name    The identification name of the streaming profile.
  # @param [Hash]   options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_details_of_a_single_streaming_profile
  def self.get_streaming_profile(name, options={})
    call_api(:get, "streaming_profiles/#{name}", {}, options)
  end

  # Updates an existing streaming profile.
  #
  # You can update both custom and built-in profiles. The specified list of representations replaces the previous list.
  #
  # @param [String] name    The name of the streaming profile to update.
  # @param [Hash]   options The optional parameters. See the
  # {https://cloudinary.com/documentation/admin_api#create_a_streaming_profile Admin API} documentation.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_a_streaming_profile
  def self.update_streaming_profile(name, options={})
    params = only(options, :display_name, :representations)
    params[:representations] = params[:representations].map do |r|
      {:transformation => Cloudinary::Utils.generate_transformation_string(r[:transformation])}
    end.to_json
    call_api(:put, "streaming_profiles/#{name}", params, options)
  end

  # Update resources access mode. Resources are selected by the prefix.
  #
  # @param [String] access_mode The access mode to set the resources to.
  # @param [String] prefix      The prefix by which to filter applicable resources
  # @param [Hash]   options     The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#examples-8
  def self.update_resources_access_mode_by_prefix(access_mode, prefix, options = {})
    update_resources_access_mode(access_mode, :prefix, prefix, options)
  end

  # Update resources access mode. Resources are selected by the tag.
  #
  # @param [String] access_mode The access mode to set the resources to.
  # @param [String] tag         The tag by which to filter applicable resources.
  # @param [Hash]   options     The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#examples-8
  def self.update_resources_access_mode_by_tag(access_mode, tag, options = {})
    update_resources_access_mode(access_mode, :tag, tag, options)
  end

  # Update resources access mode. Resources are selected by the provided public_ids.
  #
  # @param [String] access_mode The access mode to set the resources to.
  # @param [Array] public_ids   The ids by which to filter applicable resources
  # @param [Hash] options       The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#examples-8
  def self.update_resources_access_mode_by_ids(access_mode, public_ids, options = {})
    update_resources_access_mode(access_mode, :public_ids, public_ids, options)
  end

  # Gets the breakpoints.
  #
  # Returns breakpoints if defined, otherwise checks the cache(if configured), otherwise fall backs to static
  # calculation.
  #
  # @param [String] public_id Resource source.
  # @param [Hash]   options   The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @internal
  def self.get_breakpoints(public_id, options)
    local_options = options.clone
    base_transformation = Cloudinary::Utils.generate_transformation_string(local_options)
    srcset = local_options[:srcset]
    breakpoints = [:min_width, :max_width, :bytes_step, :max_images].map {|k| srcset[k]}.join('_')

    local_options[:transformation] = [base_transformation, width: "auto:breakpoints_#{breakpoints}:json"]
    json_url = Cloudinary::Utils.cloudinary_url public_id, local_options
    call_json_api('GET', json_url, {}, 60, {})
  end

  # Lists all metadata field definitions.
  #
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_metadata_fields
  def self.list_metadata_fields(options = {})
    call_metadata_api(:get, [], {}, options)
  end

  # Gets a single metadata field definition by external ID.
  #
  # @param [String] field_external_id The external ID of the field to retrieve.
  # @param [Hash]   options           The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#get_a_metadata_field_by_external_id
  def self.metadata_field_by_field_id(field_external_id, options = {})
    uri = [field_external_id]

    call_metadata_api(:get, uri, {}, options)
  end

  # Creates a new metadata field definition.
  #
  # @param [Hash] field   The field to add.
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#create_a_metadata_field
  def self.add_metadata_field(field, options = {})
    params = only(field, :type, :external_id, :label, :mandatory, :default_value, :validation, :datasource)

    call_metadata_api(:post, [], params, options)
  end

  # Updates a metadata field by external ID.
  #
  # Updates a metadata field definition (partially, no need to pass the entire object) passed as JSON data.
  #
  # @param [String] field_external_id The ID of the field to update.
  # @param [Hash]   field             The field definition.
  # @param [Hash]   options           The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_a_metadata_field_by_external_id
  def self.update_metadata_field(field_external_id, field, options = {})
    uri = [field_external_id]
    params = only(field, :label, :mandatory, :default_value, :validation)

    call_metadata_api(:put, uri, params, options)
  end

  # Deletes a metadata field definition by external ID.
  #
  # The external ID is immutable. Therefore, once deleted, the field's external ID can no longer be used for
  # future purposes.
  #
  # @param [String] field_external_id The ID of the field to delete.
  # @param [Hash]   options           The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_a_metadata_field_by_external_id
  def self.delete_metadata_field(field_external_id, options = {})
    uri = [field_external_id]

    call_metadata_api(:delete, uri, {}, options)
  end

  # Deletes entries in a metadata single or multi-select field's datasource.
  #
  # Deletes (blocks) the datasource (list) entries from the specified metadata field definition. Sets the state of
  # the entries to inactive. This is a soft delete. The entries still exist in the database and can be reactivated
  # using the restoreDatasourceEntries method.
  #
  # @param [String] field_external_id    The ID of the field to update.
  # @param [Array]  entries_external_id  The IDs of the entries to delete from the data source.
  # @param [Hash]   options              The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_entries_in_a_metadata_field_datasource
  def self.delete_datasource_entries(field_external_id, entries_external_id, options = {})
    uri = [field_external_id, "datasource"]
    params = {:external_ids => entries_external_id }

    call_metadata_api(:delete, uri, params, options)
  end

  # Updates a metadata field datasource.
  #
  # Updates the datasource of a supported field type (currently enum or set), passed as JSON data. The
  # update is partial: datasource entries with an existing external_id will be updated and entries with new
  # external_id’s (or without external_id’s) will be appended.
  #
  # @param [String] field_external_id   The ID of the field to update.
  # @param [Array]  entries_external_id A list of datasource entries. Existing entries (according to entry id) will be
  #                                     updated. New entries will be added.
  # @param [Hash]   options             The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#update_a_metadata_field_datasource
  def self.update_metadata_field_datasource(field_external_id, entries_external_id, options = {})
    uri = [field_external_id, "datasource"]

    params = entries_external_id.each_with_object({:values => [] }) do |item, hash|
      item = only(item, :external_id, :value)
      hash[:values ] << item if item.present?
    end

    call_metadata_api(:put, uri, params, options)
  end

  # Restore entries in a metadata field datasource.
  #
  # Restores (unblocks) any previously deleted datasource entries for a specified metadata field definition.
  # Sets the state of the entries to active.
  #
  # @param [String] field_external_id    The ID of the metadata field.
  # @param [Array]  entries_external_ids An array of IDs of datasource entries to restore (unblock).
  # @param [Hash]   options              The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/admin_api#restore_entries_in_a_metadata_field_datasource
  def self.restore_metadata_field_datasource(field_external_id, entries_external_ids, options = {})
    uri = [field_external_id, "datasource_restore"]
    params = {:external_ids => entries_external_ids }

    call_metadata_api(:post, uri, params, options)
  end

  # Reorders metadata field datasource. Currently supports only value.
  #
  # @param [String] field_external_id The ID of the metadata field
  # @param [String] order_by          Criteria for the order. Currently supports only value
  # @param [String] direction         Optional (gets either asc or desc)
  # @param [Hash]   options           Configuration options
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.reorder_metadata_field_datasource(field_external_id, order_by, direction = nil, options = {})
    uri    = [field_external_id, "datasource", "order"]
    params = { :order_by => order_by, :direction => direction }

    call_metadata_api(:post, uri, params, options)
  end

  # Reorders metadata fields.
  #
  # @param [String] order_by  Criteria for the order (one of the fields 'label', 'external_id', 'created_at').
  # @param [String] direction Optional (gets either asc or desc).
  # @param [Hash]   options   Configuration options.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  def self.reorder_metadata_fields(order_by, direction = nil, options = {})
    uri    = ["order"]
    params = { :order_by => order_by, :direction => direction }

    call_metadata_api(:put, uri, params, options)
  end

  # Lists all metadata rules definitions.
  #
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/conditional_metadata_rules_api#get_metadata_rules
  def self.list_metadata_rules(options = {})
    call_metadata_rules_api(:get, [], {}, options)
  end


  # Creates a new metadata rule definition.
  #
  # @param [Hash] rule    The rule to add.
  # @param [Hash] options The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/conditional_metadata_rules_api#create_a_metadata_rule
  def self.add_metadata_rule(rule, options = {})
    params = only(rule, :metadata_field_id, :condition, :result, :name)

    call_metadata_rules_api(:post, [], params, options)
  end

  # Updates a metadata rule by external ID.
  #
  # Updates an existing metadata rule definition. Expects a JSON object which defines the updated rule.
  #
  # @param [String] external_id       The ID of the rule to update.
  # @param [Hash]   rule              The rule definition.
  # @param [Hash]   options           The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/conditional_metadata_rules_api#update_a_metadata_rule_by_id
  def self.update_metadata_rule(external_id, rule, options = {})
    uri = [external_id]
    params = only(rule, :metadata_field_id, :condition, :result, :name, :state)

    call_metadata_rules_api(:put, uri, params, options)
  end

  # Deletes a metadata rule definition by external ID.
  #
  # The rule should no longer be considered a valid candidate for all other endpoints
  # (it will not show up in the list of rules, etc).
  #
  # @param [String] external_id The ID of the rule to delete.
  # @param [Hash]   options     The optional parameters.
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Cloudinary::Api::Error]
  #
  # @see https://cloudinary.com/documentation/conditional_metadata_rules_api#delete_a_metadata_rule_by_id
  def self.delete_metadata_rule(external_id, options = {})
    uri = [external_id]

    call_metadata_rules_api(:delete, uri, {}, options)
  end

  protected

  # Execute a call api for input params.
  # @param [Object] method The method for a request
  # @param [Object] uri The uri for a request
  # @param [Object] params Additional params
  # @param [Object] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.call_api(method, uri, params, options)
    cloud_name  = options[:cloud_name] || Cloudinary.config.cloud_name || raise('Must supply cloud_name')
    api_key     = options[:api_key] || Cloudinary.config.api_key
    api_secret  = options[:api_secret] || Cloudinary.config.api_secret
    oauth_token = options[:oauth_token] || Cloudinary.config.oauth_token

    validate_authorization(api_key, api_secret, oauth_token)

    auth = { :key => api_key, :secret => api_secret, :oauth_token => oauth_token }

    call_cloudinary_api(method, uri, auth, params, options) do |cloudinary, inner_uri|
      [cloudinary, 'v1_1', cloud_name, inner_uri]
    end
  end

  # Parse a json response.
  # @param [Object] response Returned response from Cloudinary
  # @return [Hash] Decoded string
  # @raise [Cloudinary::Api::GeneralError]
  def self.parse_json_response(response)
    return Cloudinary::Utils.json_decode(response.body)
  rescue => e
    # Error is parsing json
    raise GeneralError.new("Error parsing server response (#{response.code}) - #{response.body}. Got - #{e}")
  end

  # Protected function that assists with performing an API call to the metadata_fields part of the Admin API.
  #
  # @protected
  # @param [Symbol] method  The HTTP method. Valid methods: get, post, put, delete
  # @param [Array]  uri     REST endpoint of the API (without 'metadata_fields')
  # @param [Hash]   params  Query/body parameters passed to the method
  # @param [Hash]   options Additional options. Can be an override of the configuration, headers, etc.
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.call_metadata_api(method, uri, params, options)
    options[:content_type] = :json
    uri = ["metadata_fields", uri].reject(&:empty?).join("/")

    call_api(method, uri, params, options)
  end

  # Protected function that assists with performing an API call to the metadata_rules part of the Admin API.
  #
  # @protected
  # @param [Symbol] method  The HTTP method. Valid methods: get, post, put, delete
  # @param [Array]  uri     REST endpoint of the API (without 'metadata_rules')
  # @param [Hash]   params  Query/body parameters passed to the method
  # @param [Hash]   options Additional options. Can be an override of the configuration, headers, etc.
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.call_metadata_rules_api(method, uri, params, options)
    options[:content_type] = :json
    uri = ["metadata_rules", uri].reject(&:empty?).join("/")

    call_api(method, uri, params, options)
  end

  # Prepares optional parameters for asset/assetByAssetId API calls.
  # @param  [Hash]   options Additional options
  # @return [Object]         Optional parameters
  def self.prepare_resource_details_params(options)
    only(options,
         :exif,
         :colors,
         :faces,
         :quality_analysis,
         :image_metadata,
         :media_metadata,
         :phash,
         :pages,
         :cinemagraph_analysis,
         :coordinates,
         :max_results,
         :derived_next_cursor,
         :accessibility_analysis,
         :versions
    )
  end

  # Filter hash with specific keys.
  # @param [Object] hash Input hash
  # @param [Array] keys Input keys
  # @return [Hash] Result of hash filtering
  def self.only(hash, *keys)
    result = {}
    keys.each do |key|
      result[key] = hash[key] if hash.include?(key)
      result[key] = hash[key.to_s] if hash.include?(key.to_s)
    end
    result
  end

  # Merge params with a certain set of options.
  # @param [Object] options Set of options
  # @param [Hash] params Additional params
  # @return [Hash] Result of hash merging
  def self.delete_resource_params(options, params ={})
    params.merge(only(options, :keep_original, :next_cursor, :invalidate, :transformations))
  end

  # Generate a transformation string if an input a param is not a string.
  # @param [String|Hash] transformation Input transformation param
  # @return [String] Result of transformation
  def self.transformation_string(transformation)
    transformation.is_a?(String) ? transformation : Cloudinary::Utils.generate_transformation_string(transformation.clone)
  end

  # Publish resources.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_resources(options = {})
    resource_type = options[:resource_type] || "image"
    params = only(options, :public_ids, :prefix, :tag, :type, :overwrite, :invalidate)
    call_api("post", "resources/#{resource_type}/publish_resources", params, options)
  end

  # Publish resources by a prefix.
  # @param [String] prefix The name of a prefix
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_prefix(prefix, options = {})
    return self.publish_resources(options.merge(:prefix => prefix))
  end

  # Publish resources by a tag.
  # @param [String] tag The name of a tag
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_tag(tag, options = {})
    return self.publish_resources(options.merge(:tag => tag))
  end

  # Publish resources by ids.
  # @param [Array] publicIds List of public ids
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_ids(publicIds, options = {})
    return self.publish_resources(options.merge(:public_ids => publicIds))
  end

  # Build a link and prepare data for a call.
  # @param [String] access_mode The access_mode of resources
  # @param [Symbol] by_key The new access mode to be set. Possible values: public, authenticated.
  # @param [String|Array<String>] value The value to assign
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.update_resources_access_mode(access_mode, by_key, value, options = {})
    resource_type = options[:resource_type] || "image"
    type = options[:type] || "upload"
    params = only(options, :next_cursor)
    params[:access_mode] = access_mode
    params[by_key] = value
    call_api("post", "resources/#{resource_type}/#{type}/update_access_mode", params, options)
  end

  private

  RESOURCES_PARAMS = [:tags, :context, :metadata, :moderations, :fields].freeze
  LIST_RESOURCES_PARAMS = [:next_cursor, :max_results, :direction].freeze

  def self.resources_params(options, params = {})
    params.merge!(only(options, *RESOURCES_PARAMS))
    params[:fields] = Cloudinary::Utils.build_array(options[:fields]).join(",") unless params[:fields].nil?
    params
  end

  def self.list_resources_params(options, params = {})
    params.merge(resources_params(options)).merge!(only(options, *LIST_RESOURCES_PARAMS))
  end
end
