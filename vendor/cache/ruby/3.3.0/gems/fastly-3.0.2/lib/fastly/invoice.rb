require 'date'

# Invoice object
class Fastly
  # An invoice for a time period
  class Invoice < Base
    attr_accessor :start_time, :end_time, :invoice_id, :total, :regions

    ##
    # :attr: start_time
    #
    # The earliest date and time this invoice covers
    #

    ##
    # :attr: end_time
    #
    # The latest date and time this invoice covers
    #

    ##
    # :attr: total
    #
    # The total for this invoice in US dollars
    #

    ##
    # :attr: regions
    #
    # A hash reference with all the different regions and their subtotals

    # Get the start time of this invoice as a DateTime object in UTC
    def start
      DateTime.parse(start_time).new_offset(0)
    end

    # Get the end time of this invoice as a DateTime object in UTC
    def end
      DateTime.parse(end_time).new_offset(0)
    end

    private

    def self.get_path(*args)
      opts = args.size > 0 ? args[0] : {}

      url  = '/billing/v2'

      url += if opts.key?(:year) && opts.key?(:month)
               "/year/#{opts[:year]}/month/#{opts[:month]}"
             elsif opts.key?(:id)
               "/account_customers/#{opts[:customer_id]}/invoices/#{opts[:id]}"
             elsif opts.key?(:mtd)
               "/account_customers/#{opts[:customer_id]}/mtd_invoice"
             else
               "/account_customers/#{opts[:customer_id]}/invoices"
             end

      url
    end

    def self.list_path(*args)
      get_path(*args)
    end

    def self.post_path
      fail "You can't POST to an invoice"
    end

    def self.put_path
      fail "You can't PUT to an invoice"
    end

    def self.delete_path
      fail "You can't DELETE to an invoice"
    end

    def save!
      fail "You can't save an invoice"
    end

    def delete!
      fail "You can't delete an invoice"
    end
  end

  # Return an Invoice object
  #
  # If a year and month are passed in returns the invoices for that whole month.
  #
  # Otherwise it returns the invoices for the current month so far.
  def get_invoice(year = nil, month = nil)
    opts = { customer_id: current_customer.id }
    if year.nil? || month.nil?
      opts[:mtd] = true
    else
      opts[:year]  = year
      opts[:month] = month
    end

    get(Invoice, opts)
  end

  # Return an Invoice object for the passed invoice ID
  def get_invoice_by_id(id)
    opts = {
      id: id,
      customer_id: current_customer.id
    }

    get(Invoice, opts)
  end

  # Retun an array of Invoice objects.
  def list_invoices
    opts = { customer_id: current_customer.id }

    list(Invoice, opts)
  end
end
