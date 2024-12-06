require 'spec_helper'

shared_examples 'TaxRate API' do
  context 'with created tax rate' do
    let!(:rate) { Stripe::TaxRate.create }

    it 'returns list of tax rates' do
      rates = Stripe::TaxRate.list
      expect(rates.count).to eq(1)
    end

    it 'retrieves tax rate' do
      ret_rate = Stripe::TaxRate.retrieve(rate.id)
      expect(ret_rate.id).not_to be_nil
      expect(ret_rate.object).to eq('tax_rate')
      expect(ret_rate.display_name).to eq('VAT')
      expect(ret_rate.percentage).to eq(21.0)
      expect(ret_rate.jurisdiction).to eq('EU')
      expect(ret_rate.inclusive).to eq(false)
    end

    it 'updates tax rate' do
      ret_rate = Stripe::TaxRate.update(rate.id, percentage: 30.5)
      expect(ret_rate.id).not_to be_nil
      expect(ret_rate.object).to eq('tax_rate')
      expect(ret_rate.display_name).to eq('VAT')
      expect(ret_rate.percentage).to eq(30.5)
      expect(ret_rate.jurisdiction).to eq('EU')
      expect(ret_rate.inclusive).to eq(false)
    end
  end

  it 'creates tax rate' do
    rate = Stripe::TaxRate.create
    expect(rate.id).not_to be_nil
    expect(rate.object).to eq('tax_rate')
    expect(rate.display_name).to eq('VAT')
    expect(rate.percentage).to eq(21.0)
    expect(rate.jurisdiction).to eq('EU')
    expect(rate.inclusive).to eq(false)
  end
end
