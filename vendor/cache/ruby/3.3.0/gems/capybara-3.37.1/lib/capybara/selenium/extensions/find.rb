# frozen_string_literal: true

module Capybara
  module Selenium
    module Find
      def find_xpath(selector, uses_visibility: false, styles: nil, position: false, **_options)
        find_by(:xpath, selector, uses_visibility: uses_visibility, texts: [], styles: styles, position: position)
      end

      def find_css(selector, uses_visibility: false, texts: [], styles: nil, position: false, **_options)
        find_by(:css, selector, uses_visibility: uses_visibility, texts: texts, styles: styles, position: position)
      end

    private

      def find_by(format, selector, uses_visibility:, texts:, styles:, position:)
        els = find_context.find_elements(format, selector)
        hints = []

        if (els.size > 2) && !ENV['DISABLE_CAPYBARA_SELENIUM_OPTIMIZATIONS']
          els = filter_by_text(els, texts) unless texts.empty?
          hints = gather_hints(els, uses_visibility: uses_visibility, styles: styles, position: position)
        end
        els.map.with_index { |el, idx| build_node(el, hints[idx] || {}) }
      end

      def gather_hints(elements, uses_visibility:, styles:, position:)
        hints_js, functions = build_hints_js(uses_visibility, styles, position)
        return [] unless functions.any?

        (es_context.execute_script(hints_js, elements) || []).map! do |results|
          hint = {}
          hint[:style] = results.pop if functions.include?(:style_func)
          hint[:position] = results.pop if functions.include?(:position_func)
          hint[:visible] = results.pop if functions.include?(:vis_func)
          hint
        end
      rescue ::Selenium::WebDriver::Error::StaleElementReferenceError,
             ::Capybara::NotSupportedByDriverError
        # warn 'Unexpected Stale Element Error - skipping optimization'
        []
      end

      def filter_by_text(elements, texts)
        es_context.execute_script <<~JS, elements, texts
          var texts = arguments[1];
          return arguments[0].filter(function(el){
            var content = el.textContent.toLowerCase();
            return texts.every(function(txt){ return content.indexOf(txt.toLowerCase()) != -1 });
          })
        JS
      end

      def build_hints_js(uses_visibility, styles, position)
        functions = []
        hints_js = +''

        if uses_visibility && !is_displayed_atom.empty?
          hints_js << <<~VISIBILITY_JS
            var vis_func = #{is_displayed_atom};
          VISIBILITY_JS
          functions << :vis_func
        end

        if position
          hints_js << <<~POSITION_JS
            var position_func = function(el){
              return el.getBoundingClientRect();
            };
          POSITION_JS
          functions << :position_func
        end

        if styles.is_a? Hash
          hints_js << <<~STYLE_JS
            var style_func = function(el){
              var el_styles = window.getComputedStyle(el);
              return #{styles.keys.map(&:to_s)}.reduce(function(res, style){
                res[style] = el_styles[style];
                return res;
              }, {});
            };
          STYLE_JS
          functions << :style_func
        end

        hints_js << <<~EACH_JS
          return arguments[0].map(function(el){
            return [#{functions.join(',')}].map(function(fn){ return fn.call(null, el) });
          });
        EACH_JS

        [hints_js, functions]
      end

      def es_context
        respond_to?(:execute_script) ? self : driver
      end

      def is_displayed_atom # rubocop:disable Naming/PredicateName
        @@is_displayed_atom ||= begin # rubocop:disable Style/ClassVars
          browser.send(:bridge).send(:read_atom, 'isDisplayed')
        rescue StandardError
          # If the atom doesn't exist or other error
          ''
        end
      end
    end
  end
end
