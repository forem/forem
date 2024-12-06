# frozen_string_literal: true

# RemoteObjectId is from a JavaScript world, and corresponds to any JavaScript
# object, including JS wrappers for DOM nodes. There is a way to convert between
# node ids and remote object ids (DOM.requestNode and DOM.resolveNode).
#
# NodeId is used for inspection, when backend tracks the node and sends updates to
# the frontend. If you somehow got NodeId over protocol, backend should have
# pushed to the frontend all of it's ancestors up to the Document node via
# DOM.setChildNodes. After that, frontend is always kept up-to-date about anything
# happening to the node.
#
# BackendNodeId is just a unique identifier for a node. Obtaining it does not send
# any updates, for example, the node may be destroyed without any notification.
# This is a way to keep a reference to the Node, when you don't necessarily want
# to keep track of it. One example would be linking to the node from performance
# data (e.g. relayout root node). BackendNodeId may be either resolved to
# inspected node (DOM.pushNodesByBackendIdsToFrontend) or described in more
# details (DOM.describeNode).
module Ferrum
  class Frame
    module DOM
      SCRIPT_SRC_TAG = <<~JS
        const script = document.createElement("script");
        script.src = arguments[0];
        script.type = arguments[1];
        script.onload = arguments[2];
        document.head.appendChild(script);
      JS
      SCRIPT_TEXT_TAG = <<~JS
        const script = document.createElement("script");
        script.text = arguments[0];
        script.type = arguments[1];
        document.head.appendChild(script);
        arguments[2]();
      JS
      STYLE_TAG = <<~JS
        const style = document.createElement("style");
        style.type = "text/css";
        style.appendChild(document.createTextNode(arguments[0]));
        document.head.appendChild(style);
        arguments[1]();
      JS
      LINK_TAG = <<~JS
        const link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = arguments[0];
        link.onload = arguments[1];
        document.head.appendChild(link);
      JS

      #
      # Returns current top window `location href`.
      #
      # @return [String]
      #   The window's current URL.
      #
      # @example
      #   browser.go_to("https://google.com/")
      #   browser.current_url # => "https://www.google.com/"
      #
      def current_url
        evaluate("window.top.location.href")
      end

      #
      # Returns current top window title.
      #
      # @return [String]
      #   The window's current title.
      #
      # @example
      #   browser.go_to("https://google.com/")
      #   browser.current_title # => "Google"
      #
      def current_title
        evaluate("window.top.document.title")
      end

      def doctype
        evaluate("document.doctype && new XMLSerializer().serializeToString(document.doctype)")
      end

      #
      # Returns current page's html.
      #
      # @return [String]
      #   The HTML source of the current page.
      #
      # @example
      #   browser.go_to("https://google.com/")
      #   browser.body # => '<html itemscope="" itemtype="http://schema.org/WebPage" lang="ru"><head>...
      #
      def body
        evaluate("document.documentElement.outerHTML")
      end

      #
      # Finds nodes by using a XPath selector.
      #
      # @param [String] selector
      #   The XPath selector.
      #
      # @param [Node, nil] within
      #   The parent node to search within.
      #
      # @return [Array<Node>]
      #   The matching nodes.
      #
      # @example
      #   browser.go_to("https://github.com/")
      #   browser.xpath("//a[@aria-label='Issues you created']") # => [Node]
      #
      def xpath(selector, within: nil)
        expr = <<~JS
          function(selector, within) {
            let results = [];
            within ||= document

            let xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
            for (let i = 0; i < xpath.snapshotLength; i++) {
              results.push(xpath.snapshotItem(i));
            }

            return results;
          }
        JS

        evaluate_func(expr, selector, within)
      end

      #
      # Finds a node by using a XPath selector.
      #
      # @param [String] selector
      #   The XPath selector.
      #
      # @param [Node, nil] within
      #   The parent node to search within.
      #
      # @return [Node, nil]
      #   The matching node.
      #
      # @example
      #   browser.go_to("https://github.com/")
      #   browser.at_xpath("//a[@aria-label='Issues you created']") # => Node
      #
      def at_xpath(selector, within: nil)
        expr = <<~JS
          function(selector, within) {
            within ||= document
            let xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
            return xpath.snapshotItem(0);
          }
        JS
        evaluate_func(expr, selector, within)
      end

      #
      # Finds nodes by using a CSS path selector.
      #
      # @param [String] selector
      #   The CSS path selector.
      #
      # @param [Node, nil] within
      #   The parent node to search within.
      #
      # @return [Array<Node>]
      #   The matching nodes.
      #
      # @example
      #   browser.go_to("https://github.com/")
      #   browser.css("a[aria-label='Issues you created']") # => [Node]
      #
      def css(selector, within: nil)
        expr = <<~JS
          function(selector, within) {
            within ||= document
            return Array.from(within.querySelectorAll(selector));
          }
        JS

        evaluate_func(expr, selector, within)
      end

      #
      # Finds a node by using a CSS path selector.
      #
      # @param [String] selector
      #   The CSS path selector.
      #
      # @param [Node, nil] within
      #   The parent node to search within.
      #
      # @return [Node, nil]
      #   The matching node.
      #
      # @example
      #   browser.go_to("https://github.com/")
      #   browser.at_css("a[aria-label='Issues you created']") # => Node
      #
      def at_css(selector, within: nil)
        expr = <<~JS
          function(selector, within) {
            within ||= document
            return within.querySelector(selector);
          }
        JS

        evaluate_func(expr, selector, within)
      end

      #
      # Adds a `<script>` tag to the document.
      #
      # @param [String, nil] url
      #
      # @param [String, nil] path
      #
      # @param [String, nil] content
      #
      # @param [String] type
      #
      # @example
      #   browser.add_script_tag(url: "http://example.com/stylesheet.css") # => true
      #
      def add_script_tag(url: nil, path: nil, content: nil, type: "text/javascript")
        expr, *args = if url
                        [SCRIPT_SRC_TAG, url, type]
                      elsif path || content
                        if path
                          content = File.read(path)
                          content += "\n//# sourceURL=#{path}"
                        end
                        [SCRIPT_TEXT_TAG, content, type]
                      end

        evaluate_async(expr, @page.timeout, *args)
      end

      #
      # Adds a `<style>` tag to the document.
      #
      # @param [String, nil] url
      #
      # @param [String, nil] path
      #
      # @param [String, nil] content
      #
      # @example
      #   browser.add_style_tag(content: "h1 { font-size: 40px; }") # => true
      #
      def add_style_tag(url: nil, path: nil, content: nil)
        expr, *args = if url
                        [LINK_TAG, url]
                      elsif path || content
                        if path
                          content = File.read(path)
                          content += "\n//# sourceURL=#{path}"
                        end
                        [STYLE_TAG, content]
                      end

        evaluate_async(expr, @page.timeout, *args)
      end
    end
  end
end
