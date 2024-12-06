# S3DirectUpload

[![Build Status](https://travis-ci.org/waynehoover/s3_direct_upload.png)](https://travis-ci.org/waynehoover/s3_direct_upload)

Easily generate a form that allows you to upload directly to Amazon S3.
Multi file uploading supported by jquery-fileupload.

Code extracted from Ryan Bates' [gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload).

## Installation
Add this line to your application's Gemfile:

    gem 's3_direct_upload'

Then add a new initalizer with your AWS credentials:

**config/initializers/s3_direct_upload.rb**
```ruby
S3DirectUpload.config do |c|
  c.access_key_id = ""       # your access key id
  c.secret_access_key = ""   # your secret access key
  c.bucket = ""              # your bucket name
  c.region = nil             # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
  c.url = nil                # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
end
```

Make sure your AWS S3 CORS settings for your bucket look something like this:
```xml
<CORSConfiguration>
    <CORSRule>
        <AllowedOrigin>http://0.0.0.0:3000</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```
In production the AllowedOrigin key should be your domain.

Add the following js and css to your asset pipeline:

**application.js.coffee**
```coffeescript
#= require s3_direct_upload
```

**application.css**
```css
//= require s3_direct_upload_progress_bars
```

## Usage
Create a new view that uses the form helper `s3_uploader_form`:
```ruby
<%= s3_uploader_form callback_url: model_url, callback_param: "model[image_url]", id: "s3-uploader" do %>
  <%= file_field_tag :file, multiple: true %>
<% end %>
```

Note: Its required that the file_field_tag is named 'file'.

Then in your application.js.coffee, call the S3Uploader jQuery plugin on the element you created above:
```coffeescript
jQuery ->
  $("#s3-uploader").S3Uploader()
```

Optionally, you can also place this template in the same view for the progress bars:
```js+erb
<script id="template-upload" type="text/x-tmpl">
<div id="file-{%=o.unique_id%}" class="upload">
  {%=o.name%}
  <div class="progress"><div class="bar" style="width: 0%"></div></div>
</div>
</script>
```

## Options for form helper
* `callback_url:` No default. The url that is POST'd to after file is uploaded to S3. If you don't specify this option, no callback to the server will be made after the file has uploaded to S3.
* `callback_method:` Defaults to `POST`. Use PUT and remove the multiple option from your file field to update a model.
* `callback_param:` Defaults to `file`. Parameter key for the POST to `callback_url` the value will be the full s3 url of the file. If for example this is set to "model[image_url]" then the data posted would be `model[image_url] : http://bucketname.s3.amazonws.com/filename.ext`
* `key:` Defaults to `uploads/{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}`. It is the key, or filename used on s3. `{timestamp}` and `{unique_id}` are special substitution strings that will be populated by javascript with values for the current upload. `${filename}` is a special s3 string that will be populated with the original uploaded file name. Needs to be at least `"${filename}"`. It is highly recommended to use both `{unique_id}`, which will prevent collisions when uploading files with the same name (such as from a mobile device, where every photo is named image.jpg), and a server-generated random value such as `#{SecureRandom.hex}`, which adds further collision protection with other uploaders.
* `key_starts_with:` Defaults to `uploads/`. Constraint on the key on s3.  if you change the `key` option, make sure this starts with what you put there. If you set this as a blank string the upload path to s3 can be anything - not recommended!
* `acl:` Defaults to `public-read`. The AWS acl for files uploaded to s3.
* `max_file_size:` Defaults to `500.megabytes`. Maximum file size allowed.
* `id:` Optional html id for the form, its recommended that you give the form an id so you can reference with the jQuery plugin.
* `class:` Optional html class for the form.
* `data:` Optional html data attribute hash.
* `bucket:` Optional (defaults to bucket used in config).

### Example with all options
```ruby
<%= s3_uploader_form callback_url: model_url, 
                     callback_method: "POST", 
                     callback_param: "model[image_url]", 
                     key: "files/{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}", 
                     key_starts_with: "files/", 
                     acl: "public-read", 
                     max_file_size: 50.megabytes, 
                     id: "s3-uploader", 
                     class: "upload-form", 
                     data: {:key => :val} do %>
  <%= file_field_tag :file, multiple: true %>
<% end %>
```

### Example to persist the S3 url in your rails app
It is recommended that you persist the url that is sent via the POST request (to the url given to the `callback_url` option and as the key given in the `callback_param` option).

One way to do this is to make sure you have `resources model` in your routes file, and add a `s3_url` (or something similar) attribute to your model. Then make sure you have the create action in your controller for that model that saves the url from the callback_param.

You could then have your create action render a javascript file like this:
**create.js.erb**
```ruby
<% if @model.new_record? %>
  alert("Failed to upload model: <%= j @model.errors.full_messages.join(', ').html_safe %>");
<% else %>
  $("#container").append("<%= j render(@model) %>");
<% end %>
```
So that javascript code would be executed after the model instance is created, without a page refresh. See [@rbates's gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload)) for an example of that method.

Note: the POST request to the rails app also includes the following parameters `filesize`, `filetype`, `filename` and `filepath`.

### Advanced Customizations
Feel free to override the styling for the progress bars in s3_direct_upload_progress_bars.css, look at the source for inspiration.

Also feel free to write your own js to interface with jquery-file-upload. You might want to do this to do custom validations on the files before it is sent to S3 for example.
To do this remove `s3_direct_upload` from your application.js and include the necessary jquery-file-upload scripts in your asset pipeline (they are included in this gem automatically):
```cofeescript
#= require jquery-fileupload/basic
#= require jquery-fileupload/vendor/tmpl
```
Use the javascript in `s3_direct_upload` as a guide.


## Options for S3Upload jQuery Plugin

* `path:` manual path for the files on your s3 bucket. Example: `path/to/my/files/on/s3`
  Note: Your path MUST start with the option you put in your form builder for `key_starts_with`, or else you will get S3 permission errors. The file path in your s3 bucket will be `path + key`.
* `additional_data:` You can send additional data to your rails app in the persistence POST request. This would be accessible in your params hash as  `params[:key][:value]`
  Example: `{key: value}`
* `remove_completed_progress_bar:` By default, the progress bar will be removed once the file has been successfully uploaded. You can set this to `false` if you want to keep the progress bar.
* `remove_failed_progress_bar:` By default, the progress bar will not be removed when uploads fail. You can set this to `true` if you want to remove the progress bar.
* `before_add:` Callback function that executes before a file is added to the queue. It is passed file object and expects `true` or `false` to be returned. This could be useful if you would like to validate the filenames of files to be uploaded for example. If true is returned file will be uploaded as normal, false will cancel the upload.
* `progress_bar_target:` The jQuery selector for the element where you want the progress bars to be appended to. Default is the form element.
* `click_submit_target:` The jQuery selector for the element you wish to add a click handler to do the submitting instead of submiting on file open.

### Example with all options
```coffeescript
jQuery ->
  $("#myS3Uploader").S3Uploader
    path: 'path/to/my/files/on/s3'
    additional_data: {key: 'value'}
    remove_completed_progress_bar: false
    before_add: myCallBackFunction # must return true or false if set
    progress_bar_target: $('.js-progress-bars')
    click_submit_target: $('.submit-target')
```
### Example with single file upload bar without script template

This demonstrates how to use progress_bar_target and allow_multiple_files (only works with false option - single file) to show only one progress bar without script template.

```coffeescript
jQuery ->
  $("#myS3Uploader").S3Uploader
    progress_bar_target: $('.js-progress-bars')
    allow_multiple_files: false
```

Target for progress bar

```html
<div class="upload js-progress-bars">
  <div class="progress">
    <div class="bars"> </div>
  </div>
</div>
```




### Public methods
You can change the settings on your form later on by accessing the jQuery instance:

```coffeescript
jQuery ->
  v = $("#myS3Uploader").S3Uploader()
  ...
  v.path("new/path/") #only works when the key_starts_with option is blank. Not recommended.
  v.additional_data("newdata")
```

### Javascript Events Hooks

#### First upload started
`s3_uploads_start` is fired once when any batch of uploads is starting.
```coffeescript
$('#myS3Uploader').bind 's3_uploads_start', (e) ->
  alert("Uploads have started")
```

#### Successfull upload
When a file has been successfully uploaded to S3, the `s3_upload_complete` is triggered on the form. A `content` object is passed along with the following attributes :

* `url`       The full URL to the uploaded file on S3.
* `filename`  The original name of the uploaded file.
* `filepath`  The path to the file (without the filename or domain)
* `filesize`  The size of the uploaded file.
* `filetype`  The type of the uploaded file.

This hook could be used for example to fill a form hidden field with the returned S3 url :
```coffeescript
$('#myS3Uploader').bind "s3_upload_complete", (e, content) ->
  $('#someHiddenField').val(content.url)
```

#### Failed upload
When an error occured during the transferm the `s3_upload_failed` is triggered on the form with the same `content` object is passed for the successful upload with the addition of the `error_thrown` attribute. The most basic way to handle this error would be to display an alert message to the user in case the upload fails :
```coffeescript
$('#myS3Uploader').bind "s3_upload_failed", (e, content) ->
  alert("#{content.filename} failed to upload : #{content.error_thrown}")
```

#### All uploads completed
When all uploads finish in a batch an `s3_uploads_complete` event will be triggered on `document`, so you could do something like:
```coffeescript
$(document).bind 's3_uploads_complete', ->
    alert("All Uploads completed")
```

#### Rails AJAX Callbacks

In addition, the regular rails ajax callbacks will trigger on the form with regards to the POST to the server.

```coffeescript
$('#myS3Uploader').bind "ajax:success", (e, data) ->
  alert("server was notified of new file on S3; responded with '#{data}")
```

## Cleaning old uploads on S3
You may be processing the files upon upload and reuploading them to another
bucket or directory. If so you can remove the originali files by running a
rake task.

First, add the fog gem to your `Gemfile` and run `bundle`:
```ruby
  gem 'fog'
```

Then, run the rake task to delete uploads older than 2 days:
```
  $ rake s3_direct_upload:clean_remote_uploads
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/06 - PCR_RYA014-25.jpg"
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/05 - PCR_RYA014-24.jpg"
  $
```

Optionally customize the prefix used for cleaning (default is `uploads/#{2.days.ago.strftime('%Y%m%d')}`):
**config/initalizers/s3_direct_upload.rb**
```ruby
S3DirectUpload.config do |c|
  # ...
  c.prefix_to_clean = "my_path/#{1.week.ago.strftime('%y%m%d')}"
end
```

Alternately, if you'd prefer for S3 to delete your old uploads automatically, you can do
so by setting your bucket's
[Lifecycle Configuration](http://docs.aws.amazon.com/AmazonS3/latest/UG/LifecycleConfiguration.html).

## A note on IE support
IE file uploads are working but with a couple caveats.

* The before_add callback doesn't work.
* The progress bar doesn't work on IE.

But IE should still upload your files fine.


## Contributing / TODO
This is just a simple gem that only really provides some javascript and a form helper.
This gem could go all sorts of ways based on what people want and how people contribute.
Ideas:
* More specs!
* More options to control file types, ability to batch upload.
* More convention over configuration on rails side
* Create generators.
* Model methods.
* Model method to delete files from s3


## Credit
This gem is basically a small wrapper around code that [Ryan Bates](http://github.com/rbates) wrote for [Railscast#383](http://railscasts.com/episodes/383-uploading-to-amazon-s3). Most of the code in this gem was extracted from [gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload).

Thank you Ryan Bates!

This code also uses the excellecnt [jQuery-File-Upload](https://github.com/blueimp/jQuery-File-Upload), which is included in this gem by its rails counterpart [jquery-fileupload-rails](https://github.com/tors/jquery-fileupload-rails)
