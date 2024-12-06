require 'spec_helper'

shared_examples 'PaymentMethod API' do

  let(:billing_details) do
    {
      address: {
        city: 'North New Portland',
        country: 'US',
        line1: '2631 Bloomfield Way',
        line2: 'Apartment 5B',
        postal_code: '05555',
        state: 'ME'
      },
      email: 'john@example.com',
      name: 'John Doe',
      phone: '555-555-5555'
    }
  end
  let(:card_details) do
    {
      number: 4242_4242_4242_4242,
      exp_month: 9,
      exp_year: (Time.now.year + 5),
      cvc: 999
    }
  end
  let(:sepa_debit_details) do
    {
      iban: 'DE89370400440532013000'
    }
  end
  let(:ideal_details) do
    {
      bank: 'bunq'
    }
  end

  # post /v1/payment_methods
  describe 'Create a PaymentMethod', live: true do
    let(:payment_method) do
      Stripe::PaymentMethod.create(
        type: type,
        billing_details: billing_details,
        card: card_details,
        metadata: {
          order_id: '123456789'
        }
      )
    end

    context 'with credit card' do
      let(:type) { 'card' }

      it 'creates a payment method with a valid id', live: false do
        expect(payment_method.id).to match(/^test_pm/)
      end

      it 'creates a payment method with a billing address' do
        expect(payment_method.billing_details.address.city).to eq('North New Portland')
        expect(payment_method.billing_details.address.country).to eq('US')
        expect(payment_method.billing_details.address.line1).to eq('2631 Bloomfield Way')
        expect(payment_method.billing_details.address.line2).to eq('Apartment 5B')
        expect(payment_method.billing_details.address.postal_code).to eq('05555')
        expect(payment_method.billing_details.address.state).to eq('ME')
        expect(payment_method.billing_details.email).to eq('john@example.com')
        expect(payment_method.billing_details.name).to  eq('John Doe')
        expect(payment_method.billing_details.phone).to eq('555-555-5555')
      end

      it 'creates a payment method with metadata' do
        expect(payment_method.metadata.order_id).to eq('123456789')
      end
    end

    context 'with ideal' do
      let(:type) { 'ideal' }

      it 'creates a payment method with a valid id', live: false do
        expect(payment_method.id).to match(/^test_pm/)
      end

      it 'creates a payment method with a billing address' do
        expect(payment_method.billing_details.address.city).to eq('North New Portland')
        expect(payment_method.billing_details.address.country).to eq('US')
        expect(payment_method.billing_details.address.line1).to eq('2631 Bloomfield Way')
        expect(payment_method.billing_details.address.line2).to eq('Apartment 5B')
        expect(payment_method.billing_details.address.postal_code).to eq('05555')
        expect(payment_method.billing_details.address.state).to eq('ME')
        expect(payment_method.billing_details.email).to eq('john@example.com')
        expect(payment_method.billing_details.name).to  eq('John Doe')
        expect(payment_method.billing_details.phone).to eq('555-555-5555')
      end

      it 'creates a payment method with metadata' do
        expect(payment_method.metadata.order_id).to eq('123456789')
      end
    end

    context 'with sepa debit' do
      let(:type) { 'sepa_debit' }

      it 'creates a payment method with a valid id', live: false do
        expect(payment_method.id).to match(/^test_pm/)
      end

      it 'creates a payment method with a billing address' do
        expect(payment_method.billing_details.address.city).to eq('North New Portland')
        expect(payment_method.billing_details.address.country).to eq('US')
        expect(payment_method.billing_details.address.line1).to eq('2631 Bloomfield Way')
        expect(payment_method.billing_details.address.line2).to eq('Apartment 5B')
        expect(payment_method.billing_details.address.postal_code).to eq('05555')
        expect(payment_method.billing_details.address.state).to eq('ME')
        expect(payment_method.billing_details.email).to eq('john@example.com')
        expect(payment_method.billing_details.name).to  eq('John Doe')
        expect(payment_method.billing_details.phone).to eq('555-555-5555')
      end

      it 'creates a payment method with metadata' do
        expect(payment_method.metadata.order_id).to eq('123456789')
      end
    end

    context 'when type is invalid' do
      let(:type) { 'bank_account' }

      it 'raises invalid requestion exception' do
        expect { payment_method }.to raise_error(Stripe::InvalidRequestError)
      end
    end
  end

  # get /v1/payment_methods/:id
  describe 'Retrieve a PaymentMethod', live: true do
    context 'with credit card' do
      it 'retrieves a given payment method' do
        customer = Stripe::Customer.create
        original = Stripe::PaymentMethod.create(type: 'card', card: card_details)
        Stripe::PaymentMethod.attach(original.id, customer: customer.id)

        payment_method = Stripe::PaymentMethod.retrieve(original.id)

        expect(payment_method.id).to eq(original.id)
        expect(payment_method.type).to eq(original.type)
        expect(payment_method.customer).to eq(customer.id)
      end
    end

    context 'with ideal' do
      it 'retrieves a given payment method' do
        customer = Stripe::Customer.create
        original = Stripe::PaymentMethod.create(type: 'ideal', ideal: ideal_details)
        Stripe::PaymentMethod.attach(original.id, customer: customer.id)

        payment_method = Stripe::PaymentMethod.retrieve(original.id)

        expect(payment_method.id).to eq(original.id)
        expect(payment_method.type).to eq(original.type)
        expect(payment_method.customer).to eq(customer.id)
      end
    end

    context 'with sepa debit' do
      it 'retrieves a given payment method' do
        customer = Stripe::Customer.create
        original = Stripe::PaymentMethod.create(type: 'sepa_debit', sepa_debit: sepa_debit_details)
        Stripe::PaymentMethod.attach(original.id, customer: customer.id)

        payment_method = Stripe::PaymentMethod.retrieve(original.id)

        expect(payment_method.id).to eq(original.id)
        expect(payment_method.type).to eq(original.type)
        expect(payment_method.customer).to eq(customer.id)
      end
    end

    it "cannot retrieve a payment_method that doesn't exist" do
      expect { Stripe::PaymentMethod.retrieve('nope') }.to raise_error { |e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('payment_method')
        expect(e.http_status).to eq(404)
      }
    end
  end

  # get /v1/payment_methods
  describe "List a Customer's PaymentMethods", live: true do
    let(:customer1) { Stripe::Customer.create }
    let(:customer2) { Stripe::Customer.create }

    context 'with credit card' do
      before do
        3.times do
          payment_method = Stripe::PaymentMethod.create(type: 'card', card: card_details)
          Stripe::PaymentMethod.attach(payment_method.id, customer: customer1.id)
        end
      end

      it 'lists all payment methods' do
        expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'card').count).to eq(3)
      end

      context 'when passing a limit' do
        it 'only lists the limited number of payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'card', limit: 2).count).to eq(2)
        end
      end

      context 'when listing the payment methods of another customer' do
        it 'does not list any payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer2.id, type: 'card').count).to eq(0)
        end
      end
    end

    context 'with ideal' do
      before do
        3.times do
          payment_method = Stripe::PaymentMethod.create(type: 'ideal', ideal: ideal_details)
          Stripe::PaymentMethod.attach(payment_method.id, customer: customer1.id)
        end
      end

      it 'lists all payment methods' do
        expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'ideal').count).to eq(3)
      end

      context 'when passing a limit' do
        it 'only lists the limited number of payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'ideal', limit: 2).count).to eq(2)
        end
      end

      context 'when listing the payment methods of another customer' do
        it 'does not list any payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer2.id, type: 'ideal').count).to eq(0)
        end
      end
    end

    context 'with sepa debit' do
      before do
        3.times do
          payment_method = Stripe::PaymentMethod.create(type: 'sepa_debit', sepa_debit: sepa_debit_details)
          Stripe::PaymentMethod.attach(payment_method.id, customer: customer1.id)
        end
      end

      it 'lists all payment methods' do
        expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'sepa_debit').count).to eq(3)
      end

      context 'when passing a limit' do
        it 'only lists the limited number of payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer1.id, type: 'sepa_debit', limit: 2).count).to eq(2)
        end
      end

      context 'when listing the payment methods of another customer' do
        it 'does not list any payment methods' do
          expect(Stripe::PaymentMethod.list(customer: customer2.id, type: 'sepa_debit').count).to eq(0)
        end
      end
    end
  end

  # post /v1/payment_methods/:id/attach
  describe 'Attach a PaymentMethod to a Customer', live: true do
    let(:customer) { Stripe::Customer.create }

    context 'with credit card' do
      let(:payment_method) { Stripe::PaymentMethod.create(type: 'card', card: card_details) }

      it 'attaches a payment method to a customer' do
        expect { Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(nil).to(customer.id)
      end

      context "when the customer doesn't exist" do
        it 'raises invalid requestion exception' do
          expect { Stripe::PaymentMethod.attach(payment_method.id, customer: 'cus_invalid') }
            .to raise_error(Stripe::InvalidRequestError)
        end
      end
    end

    context 'with ideal' do
      let(:payment_method) { Stripe::PaymentMethod.create(type: 'ideal', ideal: ideal_details) }

      it 'attaches a payment method to a customer' do
        expect { Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(nil).to(customer.id)
      end

      context "when the customer doesn't exist" do
        it 'raises invalid requestion exception' do
          expect { Stripe::PaymentMethod.attach(payment_method.id, customer: 'cus_invalid') }
            .to raise_error(Stripe::InvalidRequestError)
        end
      end
    end

    context 'with sepa_debit' do
      let(:payment_method) { Stripe::PaymentMethod.create(type: 'sepa_debit', sepa_debit: sepa_debit_details) }

      it 'attaches a payment method to a customer' do
        expect { Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(nil).to(customer.id)
      end

      context "when the customer doesn't exist" do
        it 'raises invalid requestion exception' do
          expect { Stripe::PaymentMethod.attach(payment_method.id, customer: 'cus_invalid') }
            .to raise_error(Stripe::InvalidRequestError)
        end
      end
    end
  end

  # post /v1/payment_methods/:id/detach
  describe 'Detach a PaymentMethod from a Customer', live: true do
    let(:customer) { Stripe::Customer.create }

    context 'with credit card' do
      let(:payment_method) do
        payment_method = Stripe::PaymentMethod.create(type: 'card', card: card_details)
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)
      end

      it 'detaches a PaymentMethod from a customer' do
        expect { Stripe::PaymentMethod.detach(payment_method.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(customer.id).to(nil)
      end
    end

    context 'with ideal' do
      let(:payment_method) do
        payment_method = Stripe::PaymentMethod.create(type: 'ideal', ideal: ideal_details)
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)
      end

      it 'detaches a PaymentMethod from a customer' do
        expect { Stripe::PaymentMethod.detach(payment_method.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(customer.id).to(nil)
      end
    end

    context 'with sepa debit' do
      let(:payment_method) do
        payment_method = Stripe::PaymentMethod.create(type: 'sepa_debit', sepa_debit: sepa_debit_details)
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)
      end

      it 'detaches a PaymentMethod from a customer' do
        expect { Stripe::PaymentMethod.detach(payment_method.id) }
          .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
          .from(customer.id).to(nil)
      end
    end
  end

  # post /v1/payment_methods/:id
  describe 'Update a PaymentMethod', live: true do
    let(:customer) { Stripe::Customer.create }

    context 'with credit card' do
      let(:payment_method) do
        Stripe::PaymentMethod.create(type: 'card', card: card_details)
      end

      it 'updates the card for the payment method' do
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

        original_card_exp_month = payment_method.card.exp_month
        new_card_exp_month = 12

        expect do
          Stripe::PaymentMethod.update(payment_method.id, card: { exp_month: new_card_exp_month })
        end.to change { Stripe::PaymentMethod.retrieve(payment_method.id).card.exp_month }
          .from(original_card_exp_month).to(new_card_exp_month)
      end

      context 'without a customer' do
        it 'raises invalid requestion exception' do
          expect do
            Stripe::PaymentMethod.update(payment_method.id, card: { exp_month: 12 })
          end.to raise_error(Stripe::InvalidRequestError)
        end
      end
    end

    context 'with ideal' do
      let(:payment_method) do
        Stripe::PaymentMethod.create(type: 'ideal', ideal: ideal_details)
      end

      it 'updates the ideal for the payment method' do
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

        original_ideal_bank = payment_method.ideal.bank
        new_ideal_bank = 12

        expect do
          Stripe::PaymentMethod.update(payment_method.id, ideal: { bank: new_ideal_bank })
        end.to change { Stripe::PaymentMethod.retrieve(payment_method.id).ideal.bank }
          .from(original_ideal_bank).to(new_ideal_bank)
      end

      context 'without a customer' do
        it 'raises invalid requestion exception' do
          expect do
            Stripe::PaymentMethod.update(payment_method.id, ideal: { bank: 12 })
          end.to raise_error(Stripe::InvalidRequestError)
        end
      end
    end

    context 'with sepa debit' do
      let(:payment_method) do
        Stripe::PaymentMethod.create(type: 'sepa_debit', sepa_debit: sepa_debit_details)
      end

      it 'updates the sepa_debit for the payment method' do
        Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

        original_iban = payment_method.sepa_debit.iban
        new_iban = 'DE62370400440532013001'

        expect do
          Stripe::PaymentMethod.update(payment_method.id, sepa_debit: { iban: new_iban })
        end.to change { Stripe::PaymentMethod.retrieve(payment_method.id).sepa_debit.iban }
          .from(original_iban).to(new_iban)
      end

      context 'without a customer' do
        it 'raises invalid requestion exception' do
          expect do
            Stripe::PaymentMethod.update(payment_method.id, sepa_debit: { iban: 'DE62370400440532013001' })
          end.to raise_error(Stripe::InvalidRequestError)
        end
      end
    end
  end
end
