# frozen_string_literal: true

module Recaptcha
  module Helpers
    DEFAULT_ERRORS = {
      recaptcha_unreachable: 'Oops, we failed to validate your reCAPTCHA response. Please try again.',
      verification_failed: 'reCAPTCHA verification failed, please try again.'
    }.freeze

    def self.recaptcha_v3(options = {})
      site_key = options[:site_key] ||= Recaptcha.configuration.site_key!
      action = options.delete(:action) || raise(Recaptcha::RecaptchaError, 'action is required')
      id = options.delete(:id) || "g-recaptcha-response-data-#{dasherize_action(action)}"
      name = options.delete(:name) || "g-recaptcha-response-data[#{action}]"
      turbo = options.delete(:turbo) || options.delete(:turbolinks)
      options[:render] = site_key
      options[:script_async] ||= false
      options[:script_defer] ||= false
      options[:ignore_no_element] = options.key?(:ignore_no_element) ? options[:ignore_no_element] : true
      element = options.delete(:element)
      element = element == false ? false : :input
      if element == :input
        callback = options.delete(:callback) || recaptcha_v3_default_callback_name(action)
      end
      options[:class] = "g-recaptcha-response #{options[:class]}"

      if turbo
        options[:onload] = recaptcha_v3_execute_function_name(action)
      end
      html, tag_attributes = components(options)
      if turbo
        html << recaptcha_v3_onload_script(site_key, action, callback, id, options)
      elsif recaptcha_v3_inline_script?(options)
        html << recaptcha_v3_inline_script(site_key, action, callback, id, options)
      end
      case element
      when :input
        html << %(<input type="hidden" name="#{name}" id="#{id}" #{tag_attributes}/>\n)
      when false
        # No tag
        nil
      else
        raise(RecaptchaError, "ReCAPTCHA element `#{options[:element]}` is not valid.")
      end
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.recaptcha_tags(options)
      if options.key?(:stoken)
        raise(RecaptchaError, "Secure Token is deprecated. Please remove 'stoken' from your calls to recaptcha_tags.")
      end
      if options.key?(:ssl)
        raise(RecaptchaError, "SSL is now always true. Please remove 'ssl' from your calls to recaptcha_tags.")
      end

      noscript = options.delete(:noscript)

      html, tag_attributes, fallback_uri = components(options.dup)
      html << %(<div #{tag_attributes}></div>\n)

      if noscript != false
        html << <<-HTML
          <noscript>
            <div>
              <div style="width: 302px; height: 422px; position: relative;">
                <div style="width: 302px; height: 422px; position: absolute;">
                  <iframe
                    src="#{fallback_uri}"
                    name="ReCAPTCHA"
                    style="width: 302px; height: 422px; border-style: none; border: 0; overflow: hidden;">
                  </iframe>
                </div>
              </div>
              <div style="width: 300px; height: 60px; border-style: none;
                bottom: 12px; left: 25px; margin: 0px; padding: 0px; right: 25px;
                background: #f9f9f9; border: 1px solid #c1c1c1; border-radius: 3px;">
                <textarea id="g-recaptcha-response" name="g-recaptcha-response"
                  class="g-recaptcha-response"
                  style="width: 250px; height: 40px; border: 1px solid #c1c1c1;
                  margin: 10px 25px; padding: 0px; resize: none;">
                </textarea>
              </div>
            </div>
          </noscript>
        HTML
      end

      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.invisible_recaptcha_tags(custom)
      options = {callback: 'invisibleRecaptchaSubmit', ui: :button}.merge(custom)
      text = options.delete(:text)
      html, tag_attributes = components(options.dup)
      html << default_callback(options) if default_callback_required?(options)

      case options[:ui]
      when :button
        html << %(<button type="submit" #{tag_attributes}>#{text}</button>\n)
      when :invisible
        html << %(<div data-size="invisible" #{tag_attributes}></div>\n)
      when :input
        html << %(<input type="submit" #{tag_attributes} value="#{text}"/>\n)
      else
        raise(RecaptchaError, "ReCAPTCHA ui `#{options[:ui]}` is not valid.")
      end
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.to_error_message(key)
      default = DEFAULT_ERRORS.fetch(key) { raise ArgumentError "Unknown reCAPTCHA error - #{key}" }
      to_message("recaptcha.errors.#{key}", default)
    end

    if defined?(I18n)
      def self.to_message(key, default)
        I18n.translate(key, default: default)
      end
    else
      def self.to_message(_key, default)
        default
      end
    end

    private_class_method def self.components(options)
      html = +''
      attributes = {}
      fallback_uri = +''

      options = options.dup
      env = options.delete(:env)
      class_attribute = options.delete(:class)
      site_key = options.delete(:site_key)
      hl = options.delete(:hl)
      onload = options.delete(:onload)
      render = options.delete(:render)
      script_async = options.delete(:script_async)
      script_defer = options.delete(:script_defer)
      nonce = options.delete(:nonce)
      skip_script = (options.delete(:script) == false) || (options.delete(:external_script) == false)
      ui = options.delete(:ui)
      options.delete(:ignore_no_element)

      data_attribute_keys = [:badge, :theme, :type, :callback, :expired_callback, :error_callback, :size]
      data_attribute_keys << :tabindex unless ui == :button
      data_attributes = {}
      data_attribute_keys.each do |data_attribute|
        value = options.delete(data_attribute)
        data_attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end

      unless Recaptcha.skip_env?(env)
        site_key ||= Recaptcha.configuration.site_key!
        script_url = Recaptcha.configuration.api_server_url
        query_params = hash_to_query(
          hl: hl,
          onload: onload,
          render: render
        )
        script_url += "?#{query_params}" unless query_params.empty?
        async_attr = "async" if script_async != false
        defer_attr = "defer" if script_defer != false
        nonce_attr = " nonce='#{nonce}'" if nonce
        html << %(<script src="#{script_url}" #{async_attr} #{defer_attr} #{nonce_attr}></script>\n) unless skip_script
        fallback_uri = %(#{script_url.chomp(".js")}/fallback?k=#{site_key})
        attributes["data-sitekey"] = site_key
        attributes.merge! data_attributes
      end

      # The remaining options will be added as attributes on the tag.
      attributes["class"] = "g-recaptcha #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes, fallback_uri]
    end

    # v3

    # Renders a script that calls `grecaptcha.execute` or
    # `grecaptcha.enterprise.execute` for the given `site_key` and `action` and
    # calls the `callback` with the resulting response token.
    private_class_method def self.recaptcha_v3_inline_script(site_key, action, callback, id, options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
          // Define function so that we can call it again later if we need to reset it
          // This executes reCAPTCHA and then calls our callback.
          function #{recaptcha_v3_execute_function_name(action)}() {
            #{recaptcha_ready_method_name}(function() {
              #{recaptcha_execute_method_name}('#{site_key}', {action: '#{action}'}).then(function(token) {
                #{callback}('#{id}', token)
              });
            });
          };
          // Invoke immediately
          #{recaptcha_v3_execute_function_name(action)}()

          // Async variant so you can await this function from another async function (no need for
          // an explicit callback function then!)
          // Returns a Promise that resolves with the response token.
          async function #{recaptcha_v3_async_execute_function_name(action)}() {
            return new Promise((resolve, reject) => {
             #{recaptcha_ready_method_name}(async function() {
                resolve(await #{recaptcha_execute_method_name}('#{site_key}', {action: '#{action}'}))
              });
            })
          };

          #{recaptcha_v3_define_default_callback(callback, options) if recaptcha_v3_define_default_callback?(callback, action, options)}
        </script>
      HTML
    end

    private_class_method def self.recaptcha_v3_onload_script(site_key, action, callback, id, options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
          function #{recaptcha_v3_execute_function_name(action)}() {
            #{recaptcha_ready_method_name}(function() {
              #{recaptcha_execute_method_name}('#{site_key}', {action: '#{action}'}).then(function(token) {
                #{callback}('#{id}', token)
              });
            });
          };
          #{recaptcha_v3_define_default_callback(callback, options) if recaptcha_v3_define_default_callback?(callback, action, options)}
        </script>
      HTML
    end

    private_class_method def self.recaptcha_v3_inline_script?(options)
      !Recaptcha.skip_env?(options[:env]) &&
      options[:script] != false &&
      options[:inline_script] != false
    end

    private_class_method def self.recaptcha_v3_define_default_callback(callback, options)
      <<-HTML
        var #{callback} = function(id, token) {
          var element = document.getElementById(id);
          #{element_check_condition(options)} element.value = token;
        }
      HTML
    end

    # Returns true if we should be adding the default callback.
    # That is, if the given callback name is the default callback name (for the given action) and we
    # are not skipping inline scripts for any reason.
    private_class_method def self.recaptcha_v3_define_default_callback?(callback, action, options)
      callback == recaptcha_v3_default_callback_name(action) &&
      recaptcha_v3_inline_script?(options)
    end

    # Returns the name of the JavaScript function that actually executes the
    # reCAPTCHA code (calls `grecaptcha.execute` or
    # `grecaptcha.enterprise.execute`). You can call it again later to reset it.
    def self.recaptcha_v3_execute_function_name(action)
      "executeRecaptchaFor#{sanitize_action_for_js(action)}"
    end

    # Returns the name of an async JavaScript function that executes the reCAPTCHA code.
    def self.recaptcha_v3_async_execute_function_name(action)
      "#{recaptcha_v3_execute_function_name(action)}Async"
    end

    def self.recaptcha_v3_default_callback_name(action)
      "setInputWithRecaptchaResponseTokenFor#{sanitize_action_for_js(action)}"
    end

    # v2

    private_class_method def self.default_callback(options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce
      selector_attr = options[:id] ? "##{options[:id]}" : ".g-recaptcha"

      <<-HTML
        <script#{nonce_attr}>
          var invisibleRecaptchaSubmit = function () {
            var closestForm = function (ele) {
              var curEle = ele.parentNode;
              while (curEle.nodeName !== 'FORM' && curEle.nodeName !== 'BODY'){
                curEle = curEle.parentNode;
              }
              return curEle.nodeName === 'FORM' ? curEle : null
            };

            var el = document.querySelector("#{selector_attr}")
            if (!!el) {
              var form = closestForm(el);
              if (form) {
                form.submit();
              }
            }
          };
        </script>
      HTML
    end

    def self.recaptcha_execute_method_name
      Recaptcha.configuration.enterprise ? "grecaptcha.enterprise.execute" : "grecaptcha.execute"
    end

    def self.recaptcha_ready_method_name
      Recaptcha.configuration.enterprise ? "grecaptcha.enterprise.ready" : "grecaptcha.ready"
    end

    private_class_method def self.default_callback_required?(options)
      options[:callback] == 'invisibleRecaptchaSubmit' &&
      !Recaptcha.skip_env?(options[:env]) &&
      options[:script] != false &&
      options[:inline_script] != false
    end

    # Returns a camelized string that is safe for use in a JavaScript variable/function name.
    # sanitize_action_for_js('my/action') => 'MyAction'
    private_class_method def self.sanitize_action_for_js(action)
      action.to_s.gsub(/\W/, '_').split(/\/|_/).map(&:capitalize).join
    end

    # Returns a dasherized string that is safe for use as an HTML ID
    # dasherize_action('my/action') => 'my-action'
    private_class_method def self.dasherize_action(action)
      action.to_s.gsub(/\W/, '-').tr('_', '-')
    end

    private_class_method def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end

    private_class_method def self.element_check_condition(options)
      options[:ignore_no_element] ? "if (element !== null)" : ""
    end
  end
end
