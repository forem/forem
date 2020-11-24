# frozen_string_literal: true

module Bullet
  class Rack
    include Dependency

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless Bullet.enable?

      Bullet.start_request
      status, headers, response = @app.call(env)

      response_body = nil

      if Bullet.notification?
        if Bullet.inject_into_page? && !file?(headers) && !sse?(headers) && !empty?(response) && status == 200
          if html_request?(headers, response)
            response_body = response_body(response)
            response_body = append_to_html_body(response_body, footer_note) if Bullet.add_footer
            response_body = append_to_html_body(response_body, Bullet.gather_inline_notifications)
            response_body = append_to_html_body(response_body, xhr_script) if Bullet.add_footer
            headers['Content-Length'] = response_body.bytesize.to_s
          else
            set_header(headers, 'X-bullet-footer-text', Bullet.footer_info.uniq) if Bullet.add_footer
            set_header(headers, 'X-bullet-console-text', Bullet.text_notifications) if Bullet.console_enabled?
          end
        end
        Bullet.perform_out_of_channel_notifications(env)
      end
      [status, headers, response_body ? [response_body] : response]
    ensure
      Bullet.end_request
    end

    # fix issue if response's body is a Proc
    def empty?(response)
      # response may be ["Not Found"], ["Move Permanently"], etc, but
      # those should not happen if the status is 200
      body = response_body(response)
      body.nil? || body.empty?
    end

    def append_to_html_body(response_body, content)
      body = response_body.dup
      content = content.html_safe if content.respond_to?(:html_safe)
      if body.include?('</body>')
        position = body.rindex('</body>')
        body.insert(position, content)
      else
        body << content
      end
    end

    def footer_note
      "<details #{details_attributes}><summary #{summary_attributes}>Bullet Warnings</summary><div #{footer_content_attributes}>#{Bullet.footer_info.uniq.join('<br>')}#{footer_console_message}</div></details>"
    end

    def set_header(headers, header_name, header_array)
      # Many proxy applications such as Nginx and AWS ELB limit
      # the size a header to 8KB, so truncate the list of reports to
      # be under that limit
      header_array.pop while header_array.to_json.length > 8 * 1024
      headers[header_name] = header_array.to_json
    end

    def file?(headers)
      headers['Content-Transfer-Encoding'] == 'binary' || headers['Content-Disposition']
    end

    def sse?(headers)
      headers['Content-Type'] == 'text/event-stream'
    end

    def html_request?(headers, response)
      headers['Content-Type']&.include?('text/html') && response_body(response).include?('<html')
    end

    def response_body(response)
      if response.respond_to?(:body)
        Array === response.body ? response.body.first : response.body
      else
        response.first
      end
    end

    private

    def details_attributes
      <<~EOF
        id="bullet-footer" data-is-bullet-footer
        style="cursor: pointer; position: fixed; left: 0px; bottom: 0px; z-index: 9999; background: #fdf2f2; color: #9b1c1c; font-size: 12px; border-radius: 0px 8px 0px 0px; border: 1px solid #9b1c1c;"
      EOF
    end

    def summary_attributes
      <<~EOF
        style="font-weight: 600; padding: 2px 8px"
      EOF
    end

    def footer_content_attributes
      <<~EOF
        style="padding: 8px; border-top: 1px solid #9b1c1c;"
      EOF
    end

    def footer_console_message
      if Bullet.console_enabled?
        "<br/><span style='font-style: italic;'>See 'Uniform Notifier' in JS Console for Stacktrace</span>"
      end
    end

    # Make footer work for XHR requests by appending data to the footer
    def xhr_script
      "<script type='text/javascript'>#{File.read("#{__dir__}/bullet_xhr.js")}</script>"
    end
  end
end
