require 'spec_helper'

shared_examples 'Invoice Item API' do

  context "creating a new invoice item" do
    it "creates a stripe invoice item" do
      invoice_item = Stripe::InvoiceItem.create({
        amount: 1099,
        customer: 1234,
        currency: 'USD',
        description: "invoice item desc"
      }, 'abcde')

      expect(invoice_item.id).to match(/^test_ii/)
      expect(invoice_item.amount).to eq(1099)
      expect(invoice_item.description).to eq('invoice item desc')
    end

    it "stores a created stripe invoice item in memory" do
      invoice_item = Stripe::InvoiceItem.create
      data = test_data_source(:invoice_items)
      expect(data[invoice_item.id]).to_not be_nil
      expect(data[invoice_item.id][:id]).to eq(invoice_item.id)
    end
  end

  context "retrieving an invoice item" do
    it "retrieves a stripe invoice item" do
      original = Stripe::InvoiceItem.create
      invoice_item = Stripe::InvoiceItem.retrieve(original.id)
      expect(invoice_item.id).to eq(original.id)
    end
  end

  context "retrieving a list of invoice items" do
    before do
      Stripe::InvoiceItem.create({ amount: 1075 })
      Stripe::InvoiceItem.create({ amount: 1540 })
    end

    it "retrieves all invoice items" do
      all = Stripe::InvoiceItem.list
      expect(all.count).to eq(2)
      expect(all.map &:amount).to include(1075, 1540)
    end
  end

  it "updates a stripe invoice_item" do
    original = Stripe::InvoiceItem.create(id: 'test_invoice_item_update')
    amount = original.amount

    original.description = 'new desc'
    original.save

    expect(original.amount).to eq(amount)
    expect(original.description).to eq('new desc')

    invoice_item = Stripe::InvoiceItem.retrieve("test_invoice_item_update")
    expect(invoice_item.amount).to eq(original.amount)
    expect(invoice_item.description).to eq('new desc')
  end

  it "deletes a invoice_item" do
    invoice_item = Stripe::InvoiceItem.create(id: 'test_invoice_item_sub')
    invoice_item = invoice_item.delete
    expect(invoice_item.deleted).to eq true
  end

end
