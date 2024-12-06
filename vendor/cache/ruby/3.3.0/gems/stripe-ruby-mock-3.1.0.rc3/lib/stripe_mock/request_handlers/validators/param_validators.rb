module StripeMock
  module RequestHandlers
    module ParamValidators

      def already_exists_message(obj_class)
        "#{obj_class.to_s.split("::").last} already exists."
      end

      def not_found_message(obj_class, obj_id)
        "No such #{obj_class.to_s.split("::").last.downcase}: #{obj_id}"
      end

      def missing_param_message(attr_name)
        "Missing required param: #{attr_name}."
      end

      def invalid_integer_message(my_val)
        "Invalid integer: #{my_val}"
      end

      #
      # ProductValidator
      #


      def validate_create_product_params(params)
        params[:id] = params[:id].to_s
        @base_strategy.create_product_params.keys.reject{ |k,_| k == :id }.each do |k|
          raise Stripe::InvalidRequestError.new(missing_param_message(k), k) if params[k].nil?
        end

        if products[ params[:id] ]
          raise Stripe::InvalidRequestError.new(already_exists_message(Stripe::Product), :id)
        end
      end

      #
      # PlanValidator
      #

      def missing_plan_amount_message
        "Plans require an `amount` parameter to be set."
      end

      SUPPORTED_PLAN_INTERVALS = ["month", "year", "week", "day"]

      def invalid_plan_interval_message
        "Invalid interval: must be one of day, month, week, or year"
      end

      SUPPORTED_CURRENCIES = [
        "usd", "aed", "afn", "all", "amd", "ang", "aoa", "ars", "aud", "awg", "azn", "bam", "bbd", "bdt", "bgn",
        "bif", "bmd", "bnd", "bob", "brl", "bsd", "bwp", "bzd", "cad", "cdf", "chf", "clp", "cny", "cop", "crc",
        "cve", "czk", "djf", "dkk", "dop", "dzd", "egp", "etb", "eur", "fjd", "fkp", "gbp", "gel", "gip", "gmd",
        "gnf", "gtq", "gyd", "hkd", "hnl", "hrk", "htg", "huf", "idr", "ils", "inr", "isk", "jmd", "jpy", "kes",
        "kgs", "khr", "kmf", "krw", "kyd", "kzt", "lak", "lbp", "lkr", "lrd", "lsl", "mad", "mdl", "mga", "mkd",
        "mmk", "mnt", "mop", "mro", "mur", "mvr", "mwk", "mxn", "myr", "mzn", "nad", "ngn", "nio", "nok", "npr",
        "nzd", "pab", "pen", "pgk", "php", "pkr", "pln", "pyg", "qar", "ron", "rsd", "rub", "rwf", "sar", "sbd",
        "scr", "sek", "sgd", "shp", "sll", "sos", "srd", "std", "szl", "thb", "tjs", "top", "try", "ttd", "twd",
        "tzs", "uah", "ugx", "uyu", "uzs", "vnd", "vuv", "wst", "xaf", "xcd", "xof", "xpf", "yer", "zar", "zmw",
        "eek", "lvl", "svc", "vef", "ltl"
      ]

      def invalid_currency_message(my_val)
        "Invalid currency: #{my_val.downcase}. Stripe currently supports these currencies: #{SUPPORTED_CURRENCIES.join(", ")}"
      end

      def validate_create_plan_params(params)
        plan_id = params[:id].to_s
        product_id = params[:product]

        @base_strategy.create_plan_params.keys.each do |attr_name|
          message =
            if attr_name == :amount
              "Plans require an `#{attr_name}` parameter to be set."
            else
              "Missing required param: #{attr_name}."
            end
          raise Stripe::InvalidRequestError.new(message, attr_name) if params[attr_name].nil?
        end

        if plans[plan_id]
          message = already_exists_message(Stripe::Plan)
          raise Stripe::InvalidRequestError.new(message, :id)
        end

        unless products[product_id]
          message = not_found_message(Stripe::Product, product_id)
          raise Stripe::InvalidRequestError.new(message, :product)
        end

        unless SUPPORTED_PLAN_INTERVALS.include?(params[:interval])
          message = invalid_plan_interval_message
          raise Stripe::InvalidRequestError.new(message, :interval)
        end

        unless SUPPORTED_CURRENCIES.include?(params[:currency])
          message = invalid_currency_message(params[:currency])
          raise Stripe::InvalidRequestError.new(message, :currency)
        end

        unless params[:amount].integer?
          message = invalid_integer_message(params[:amount])
          raise Stripe::InvalidRequestError.new(message, :amount)
        end

      end

      def validate_create_price_params(params)
        price_id = params[:id].to_s
        product_id = params[:product]

        @base_strategy.create_price_params.keys.each do |attr_name|
          message = "Missing required param: #{attr_name}."
          raise Stripe::InvalidRequestError.new(message, attr_name) if params[attr_name].nil?
        end

        if prices[price_id]
          message = already_exists_message(Stripe::Price)
          raise Stripe::InvalidRequestError.new(message, :id)
        end

        unless products[product_id]
          message = not_found_message(Stripe::Product, product_id)
          raise Stripe::InvalidRequestError.new(message, :product)
        end

        unless SUPPORTED_CURRENCIES.include?(params[:currency])
          message = invalid_currency_message(params[:currency])
          raise Stripe::InvalidRequestError.new(message, :currency)
        end
      end

      def validate_list_prices_params(params)
        if params[:lookup_keys] && !params[:lookup_keys].is_a?(Array)
          raise Stripe::InvalidRequestError.new('Invalid array', :lookup_keys)
        end
      end

      def require_param(param_name)
        raise Stripe::InvalidRequestError.new("Missing required param: #{param_name}.", param_name.to_s, http_status: 400)
      end

    end
  end
end
