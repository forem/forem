require 'spec_helper'

shared_examples 'Coupon API' do
  context 'create coupon' do
    let(:coupon) { stripe_helper.create_coupon }

    it 'creates a stripe coupon', live: true do
      expect(coupon.id).to eq('10BUCKS')
      expect(coupon.amount_off).to eq(1000)

      expect(coupon.currency).to eq('usd')
      expect(coupon.max_redemptions).to eq(100)
      expect(coupon.metadata.to_hash).to eq( { :created_by => 'admin_acct_1' } )
      expect(coupon.duration).to eq('once')
    end
    it 'stores a created stripe coupon in memory' do
      coupon

      data = test_data_source(:coupons)

      expect(data[coupon.id]).to_not be_nil
      expect(data[coupon.id][:amount_off]).to eq(1000)
    end
    it 'fails when a coupon is created without a duration' do
      expect { Stripe::Coupon.create(id: '10PERCENT') }.to raise_error {|e|
                 expect(e).to be_a(Stripe::InvalidRequestError)
                 expect(e.message).to match /duration/
             }
    end
    it 'fails when a coupon is created without a currency when amount_off is specified' do
      expect { Stripe::Coupon.create(id: '10OFF', duration: 'once', amount_off: 1000) }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to match /You must pass currency when passing amount_off/
      }
    end
  end

  context 'retrieve coupon', live: true do
    let(:coupon1) { stripe_helper.create_coupon }
    let(:coupon2) { stripe_helper.create_coupon(id: '11BUCKS', amount_off: 3000) }

    it 'retrieves a stripe coupon' do
      coupon1

      coupon = Stripe::Coupon.retrieve(coupon1.id)

      expect(coupon.id).to eq(coupon1.id)
      expect(coupon.amount_off).to eq(coupon1.amount_off)
    end
    it 'retrieves all coupons' do
      stripe_helper.delete_all_coupons

      coupon1
      coupon2

      all = Stripe::Coupon.list

      expect(all.count).to eq(2)
      expect(all.map &:id).to include('10BUCKS', '11BUCKS')
      expect(all.map &:amount_off).to include(1000, 3000)
    end
    it "cannot retrieve a stripe coupon that doesn't exist" do
      expect { Stripe::Coupon.retrieve('nope') }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('coupon')
        expect(e.http_status).to eq(404)
      }
    end
  end

  context 'Delete coupon', live: true do
    it 'deletes a stripe coupon' do
      original = stripe_helper.create_coupon
      coupon = Stripe::Coupon.retrieve(original.id)

      coupon.delete

      expect { Stripe::Coupon.retrieve(coupon.id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('coupon')
        expect(e.http_status).to eq(404)
      }
    end
  end
end
