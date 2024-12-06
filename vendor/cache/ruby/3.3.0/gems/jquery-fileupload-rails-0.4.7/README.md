# jQuery File Upload for Rails

[jQuery-File-Plugin](https://github.com/blueimp/jQuery-File-Upload) is a file upload plugin written by [Sebastian Tschan](https://github.com/blueimp). jQuery File Upload features multiple file selection, drag&drop support, progress bars and preview images for jQuery. Supports cross-domain, chunked and resumable file uploads and client-side image resizing.

jquery-fileupload-rails is a library that integrates jQuery File Upload for Rails 3.1 Asset Pipeline (Rails 3.2 supported).

## Plugin versions

* jQuery File Upload Plugin v9.12.5

## Installing Gem

    gem "jquery-fileupload-rails"

## Using the javascripts

Require jquery-fileupload in your app/assets/application.js file.

    //= require jquery-fileupload

The snippet above will add the following js files to the manifest file.

    //= require jquery-fileupload/vendor/jquery.ui.widget
    //= require jquery-fileupload/vendor/tmpl
    //= require jquery-fileupload/vendor/load-image.all.min
    //= require jquery-fileupload/vendor/canvas-to-blob
    //= require jquery-fileupload/jquery.iframe-transport
    //= require jquery-fileupload/jquery.fileupload
    //= require jquery-fileupload/jquery.fileupload-process
    //= require jquery-fileupload/jquery.fileupload-image
    //= require jquery-fileupload/jquery.fileupload-audio
    //= require jquery-fileupload/jquery.fileupload-video
    //= require jquery-fileupload/jquery.fileupload-validate
    //= require jquery-fileupload/jquery.fileupload-ui
    //= require jquery-fileupload/locale
    //= require jquery-fileupload/jquery.fileupload-angular
    //= require jquery-fileupload/jquery.fileupload-jquery-ui
    //= require jquery-fileupload/cors/jquery.postmessage-transport
    //= require jquery-fileupload/cors/jquery.xdr-transport

If you only need the basic files, just add the code below to your application.js file. [Basic setup guide](https://github.com/blueimp/jQuery-File-Upload/wiki/Basic-plugin)

    //= require jquery-fileupload/basic

The basic setup only includes the following files:

    //= require jquery-fileupload/vendor/jquery.ui.widget
    //= require jquery-fileupload/jquery.iframe-transport
    //= require jquery-fileupload/jquery.fileupload

You can also require the following to get the js from the Basic-Plus, AngularJS and jQuery UI Examples:

    //= require jquery-fileupload/basic-plus

    //= require jquery-fileupload/angularjs

    //= require jquery-fileupload/jquery-ui

## Using the stylesheet

Require the stylesheet file to app/assets/stylesheets/application.css

    *= require jquery.fileupload
    *= require jquery.fileupload-ui

There are also noscript styles for Browsers with Javascript disabled, to use them create a noscript.css and add it to your precompile-list and layout inside a noscript tag:

    *= require jquery.fileupload-noscript
    *= require jquery.fileupload-ui-noscript

## Using the middleware

The `jquery.iframe-transport` fallback transport has some special caveats regarding the response data type, http status, and character encodings. `jquery-fileupload-rails` includes a middleware that handles these inconsistencies seamlessly. If you decide to use it, create an initializer that adds the middleware to your application's middleware stack.

    Rails.application.config.middleware.use JQuery::FileUpload::Rails::Middleware

## Example apps
[jquery-fileupload-rails-paperclip-example](https://github.com/tors/jquery-fileupload-rails-paperclip-example): jQuery File Upload in Rails 3.2 with Paperclip and Bootstrap

[rails-resumable-jquery-fileupload](https://github.com/vgantchev/rails-resumable-jquery-fileupload): resumable (chunked) uploads with jQuery File Upload in Rails 4.2 using Paperclip

You can also check out Ryan Bate's RailsCast [jQuery File Upload episode](http://railscasts.com/episodes/381-jquery-file-upload). You will
need a pro account to watch it though.


## Thanks
Thanks to [Sebastian Tschan](https://github.com/blueimp) for writing an awesome file upload plugin.

## License
Copyright (c) 2012 Tors Dalid

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
