require 'spec_helper'

shared_examples 'Invoice API' do

  context "creating a new invoice" do
    it "creates a stripe invoice" do
      invoice = Stripe::Invoice.create
      expect(invoice.id).to match(/^test_in/)
    end

    it "stores a created stripe invoice in memory" do
      invoice = Stripe::Invoice.create
      data = test_data_source(:invoices)
      expect(data[invoice.id]).to_not be_nil
      expect(data[invoice.id][:id]).to eq(invoice.id)
    end
  end

  context "retrieving an invoice" do
    it "retrieves a stripe invoice" do
      original = Stripe::Invoice.create
      invoice = Stripe::Invoice.retrieve(original.id)
      expect(invoice.id).to eq(original.id)
    end
  end

  context "updating an invoice" do
    it "updates a stripe invoice" do
      invoice = Stripe::Invoice.create(currency: "cad", statement_description: "orig-desc")
      expect(invoice.currency).to eq("cad")
      expect(invoice.statement_description).to eq("orig-desc")

      invoice.currency = "usd"
      invoice.statement_description = "new-desc"
      invoice.save

      invoice = Stripe::Invoice.retrieve(invoice.id)
      expect(invoice.currency).to eq("usd")
      expect(invoice.statement_description).to eq("new-desc")
    end
  end

  context "retrieving a list of invoices" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
      @invoice = Stripe::Invoice.create(customer: @customer.id)
      @invoice2 = Stripe::Invoice.create
    end

    it "stores invoices for a customer in memory" do
      invoices = Stripe::Invoice.list(customer: @customer.id)
      expect(invoices.map(&:id)).to eq([@invoice.id])
    end

    it "stores all invoices in memory" do
      expect(Stripe::Invoice.list.map(&:id)).to match_array([@invoice.id, @invoice2.id])
    end

    it "defaults count to 10 invoices" do
      11.times { Stripe::Invoice.create }
      expect(Stripe::Invoice.list.count).to eq(10)
    end

    it "is marked as having more when more objects exist" do
      11.times { Stripe::Invoice.create }

      expect(Stripe::Invoice.list.has_more).to eq(true)
    end

    context "when passing limit" do
      it "gets that many invoices" do
        expect(Stripe::Invoice.list(limit: 1).count).to eq(1)
      end
    end
  end

  context "paying an invoice" do
    before do
      @invoice = Stripe::Invoice.create
    end

    it 'updates attempted and paid flags' do
      @invoice = @invoice.pay
      expect(@invoice.attempted).to eq(true)
      expect(@invoice.paid).to eq(true)
    end

    it 'creates a new charge object' do
      expect{ @invoice.pay }.to change { Stripe::Charge.list.data.count }.by 1
    end

    it 'sets the charge attribute' do
      @invoice = @invoice.pay
      expect(@invoice.charge).to be_a String
      expect(@invoice.charge.length).to be > 0
    end

    it 'charges the invoice customers default card' do
      customer = Stripe::Customer.create({
        source: stripe_helper.generate_card_token
      })
      customer_invoice = Stripe::Invoice.create({customer: customer})

      customer_invoice.pay

      expect(Stripe::Charge.list.data.first.customer).to eq customer.id
    end
  end

  context "retrieving upcoming invoice" do
    let(:customer)      { Stripe::Customer.create(source: stripe_helper.generate_card_token) }
    let(:coupon_amtoff) { stripe_helper.create_coupon(id: '100OFF', currency: 'usd', amount_off: 100_00, duration: 'repeating', duration_in_months: 6) }
    let(:coupon_pctoff) { stripe_helper.create_coupon(id: '50OFF', currency: 'usd', percent_off: 50, amount_off: nil, duration: 'repeating', duration_in_months: 6) }
    let(:product)       { stripe_helper.create_product(id: "prod_123") }
    let(:plan)          { stripe_helper.create_plan(id: '50m', product: product.id, amount: 50_00, interval: 'month', nickname: '50m', currency: 'usd') }
    let(:quantity)      { 3 }
    let(:subscription)  { Stripe::Subscription.create(plan: plan.id, customer: customer.id, quantity: quantity) }

    before(with_customer:         true) { customer }
    before(with_coupon_amtoff:    true) { coupon_amtoff }
    before(with_coupon_pctoff:    true) { coupon_pctoff }
    before(with_discount_amtoff:  true) { customer.coupon = coupon_amtoff.id; customer.save }
    before(with_discount_pctoff:  true) { customer.coupon = coupon_pctoff.id; customer.save }
    before(with_plan:             true) { plan }
    before(with_subscription:     true) { subscription }

    # after { subscription.delete   rescue nil if @teardown_subscription }
    # after { plan.delete           rescue nil if @teardown_plan }
    # after { coupon_pctoff.delete  rescue nil if @teardown_coupon_pctoff }
    # after { coupon_amtoff.delete  rescue nil if @teardown_coupon_amtoff }
    # after { customer.delete       rescue nil if @teardown_customer }

    describe 'parameter validation' do
      it 'fails without parameters' do
        expect { Stripe::Invoice.upcoming() }.to raise_error {|e|
          expect(e).to be_a(ArgumentError) }
      end

      it 'fails without a valid customer' do
        expect { Stripe::Invoice.upcoming(customer: 'whatever') }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq('No such customer: whatever') }
      end

      it 'fails without a customer parameter' do
        expect { Stripe::Invoice.upcoming(gazebo: 'raindance') }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.http_status).to eq(400)
          expect(e.message).to eq('Missing required param: customer if subscription is not provided') }
      end

      it 'fails without a subscription' do
        expect { Stripe::Invoice.upcoming(customer: customer.id) }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.http_status).to eq(404)
          expect(e.message).to eq("No upcoming invoices for customer: #{customer.id}") }
      end
    end

    describe 'parameter validation' do
      it 'fails without a subscription or subscription plan if subscription proration date is specified', live: true do
        expect { Stripe::Invoice.upcoming(customer: customer.id, subscription_proration_date: Time.now.to_i) }.to raise_error do |e|
          expect(e).to be_a Stripe::InvalidRequestError
          expect(e.http_status).to eq 400
          expect(e.message).to eq 'When previewing changes to a subscription, you must specify either `subscription` or `subscription_items`'
        end
      end

      it 'fails without a subscription if proration date is specified', live: true, with_subscription: true do
        expect { Stripe::Invoice.upcoming(customer: customer.id, subscription_plan: plan.id, subscription_proration_date: Time.now.to_i) }.to raise_error do |e|
          expect(e).to be_a Stripe::InvalidRequestError
          expect(e.http_status).to eq 400
          expect(e.message).to eq 'Cannot specify proration date without specifying a subscription'
        end
      end
    end

    it 'considers current subscription', live: true, with_subscription: true do
      # When
      upcoming = Stripe::Invoice.upcoming(customer: customer.id)

      # Then
      expect(upcoming).to be_a Stripe::Invoice
      expect(upcoming.customer).to eq(customer.id)
      expect(upcoming.amount_due).to eq plan.amount * quantity
      expect(upcoming.total).to eq(upcoming.lines.data[0].amount)
      expect(upcoming.period_end).to eq(upcoming.lines.data[0].period.start)
      expect(Time.at(upcoming.period_start).to_datetime >> 1).to eq(Time.at(upcoming.period_end).to_datetime) # +1 month
      expect(Time.at(upcoming.period_start).to_datetime >> 2).to eq(Time.at(upcoming.lines.data[0].period.end).to_datetime) # +1 month
      expect(upcoming.next_payment_attempt).to eq(upcoming.period_end + 3600) # +1 hour
      expect(upcoming.subscription).to eq(subscription.id)
    end

    describe 'discounts' do
      it 'considers a $ off discount', live: true, with_discount_amtoff: true, with_subscription: true do
        # When
        upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        # Then
        expect(upcoming.discount).not_to be_nil
        expect(upcoming.discount.coupon.id).to eq '100OFF'
        expect(upcoming.discount.customer).to eq customer.id
        expect(upcoming.discount.start).to be_within(60).of Time.now.to_i
        expect(upcoming.discount.end).to be_within(60).of (Time.now.to_datetime >> 6).to_time.to_i
        expect(upcoming.amount_due).to eq plan.amount * quantity - 100_00
        expect(upcoming.subtotal).to eq(upcoming.lines.data[0].amount)
        expect(upcoming.total).to eq upcoming.subtotal - 100_00
      end

      it 'considers a % off discount', live: true, with_discount_pctoff: true, with_subscription: true do
        # When
        upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        # Then
        expect(upcoming.discount).not_to be_nil
        expect(upcoming.discount.coupon.id).to eq '50OFF'
        expect(upcoming.discount.customer).to eq customer.id
        expect(upcoming.discount.start).to be_within(60).of Time.now.to_i
        expect(upcoming.discount.end).to be_within(60).of (Time.now.to_datetime >> 6).to_time.to_i
        expect(upcoming.amount_due).to eq (plan.amount * quantity) * 0.5
        expect(upcoming.subtotal).to eq(upcoming.lines.data[0].amount)
        expect(upcoming.total).to eq upcoming.subtotal * 0.5
      end
    end

    describe 'proration' do
      shared_examples 'failing when proration date is outside of the subscription current period' do
        it 'fails', live: true, skip: 'Stripe does not raise error anymore' do
          expect { Stripe::Invoice.upcoming(
              customer: customer.id,
              subscription: subscription.id,
              subscription_plan: plan.id,
              subscription_quantity: quantity,
              subscription_proration_date: proration_date.to_i,
              subscription_trial_end: nil
          ) }.to raise_error {|e|
            expect(e).to be_a(Stripe::InvalidRequestError)
            expect(e.http_status).to eq(400)
            expect(e.message).to eq('Cannot specify proration date outside of current subscription period') }
        end
      end

      it_behaves_like 'failing when proration date is outside of the subscription current period' do
        let(:proration_date) { subscription.current_period_start - 1 }
      end

      it_behaves_like 'failing when proration date is outside of the subscription current period' do
        let(:proration_date) { subscription.current_period_end + 1 }
      end

      [false, true].each do |with_trial|
        describe "prorating a subscription with a new plan, with_trial: #{with_trial}" do
          let(:new_monthly_plan) { stripe_helper.create_plan(id: '100m', product: product.id, amount: 100_00, interval: 'month') }
          let(:new_yearly_plan) { stripe_helper.create_plan(id: '100y', product: product.id, amount: 100_00, interval: 'year') }
          let(:plan) { stripe_helper.create_plan(id: '50m', product: product.id, amount: 50_00, interval: 'month') }

          it 'prorates while maintaining billing interval', live: true do
            # Given
            proration_date = Time.now + 5 * 24 * 3600 # 5 days later
            new_quantity = 2
            unused_amount = plan.amount * quantity * (subscription.current_period_end - proration_date.to_i) / (subscription.current_period_end - subscription.current_period_start)
            remaining_amount = new_monthly_plan.amount * new_quantity * (subscription.current_period_end - proration_date.to_i) / (subscription.current_period_end - subscription.current_period_start)
            prorated_amount_due = new_monthly_plan.amount * new_quantity - unused_amount + remaining_amount
            credit_balance = 1000
            customer.account_balance = -credit_balance
            customer.save
            query = { customer: customer.id, subscription: subscription.id, subscription_plan: new_monthly_plan.id, subscription_proration_date: proration_date.to_i, subscription_quantity: new_quantity }
            query[:subscription_trial_end] = (DateTime.now >> 1).to_time.to_i if with_trial

            # When
            upcoming = Stripe::Invoice.upcoming(query)

            # Then
            expect(upcoming).to be_a Stripe::Invoice
            expect(upcoming.customer).to eq(customer.id)
            expect(upcoming.starting_balance).to eq -credit_balance
            expect(upcoming.subscription).to eq(subscription.id)

            if with_trial
              expect(upcoming.amount_due).to be_within(1).of 0
              expect(upcoming.lines.data.length).to eq(2)
              # expect(upcoming.ending_balance).to be_within(50).of -13540 # -13322
            else
              expect(upcoming.amount_due).to be_within(1).of prorated_amount_due - credit_balance
              expect(upcoming.lines.data.length).to eq(3)
              expect(upcoming.ending_balance).to eq 0
            end

            expect(upcoming.lines.data[0].proration).to be_truthy
            expect(upcoming.lines.data[0].plan.id).to eq '50m'
            expect(upcoming.lines.data[0].amount).to be_within(1).of -unused_amount
            expect(upcoming.lines.data[0].quantity).to eq quantity

            unless with_trial
              expect(upcoming.lines.data[1].proration).to be_truthy
              expect(upcoming.lines.data[1].plan.id).to eq '100m'
              expect(upcoming.lines.data[1].amount).to be_within(1).of remaining_amount
              expect(upcoming.lines.data[1].quantity).to eq new_quantity
            end

            expect(upcoming.lines.data.last.proration).to be_falsey
            expect(upcoming.lines.data.last.plan.id).to eq '100m'
            expect(upcoming.lines.data.last.amount).to eq with_trial ? 0 : 20000
            expect(upcoming.lines.data.last.quantity).to eq new_quantity
          end

          it 'prorates while changing billing intervals', live: true do
            # Given
            proration_date = Time.now + 5 * 24 * 3600 # 5 days later
            new_quantity = 2
            unused_amount = (plan.amount.to_f * quantity * (subscription.current_period_end - proration_date.to_i) / (subscription.current_period_end - subscription.current_period_start)).round
            prorated_amount_due = new_yearly_plan.amount * new_quantity - unused_amount
            credit_balance = 1000
            amount_due = prorated_amount_due - credit_balance
            customer.account_balance = -credit_balance
            customer.save
            query = { customer: customer.id, subscription: subscription.id, subscription_plan: new_yearly_plan.id, subscription_proration_date: proration_date.to_i, subscription_quantity: new_quantity }
            query[:subscription_trial_end] = (DateTime.now >> 1).to_time.to_i if with_trial

            # When
            upcoming = Stripe::Invoice.upcoming(query)

            # Then
            expect(upcoming).to be_a Stripe::Invoice
            expect(upcoming.customer).to eq(customer.id)
            if with_trial
              # expect(upcoming.ending_balance).to be_within(50).of -13540 # -13322
              expect(upcoming.amount_due).to eq 0
            else
              expect(upcoming.ending_balance).to eq 0
              expect(upcoming.amount_due).to be_within(1).of amount_due
            end
            expect(upcoming.starting_balance).to eq -credit_balance
            expect(upcoming.subscription).to eq(subscription.id)

            expect(upcoming.lines.data[0].proration).to be_truthy
            expect(upcoming.lines.data[0].plan.id).to eq '50m'
            expect(upcoming.lines.data[0].amount).to be_within(1).of -unused_amount
            expect(upcoming.lines.data[0].quantity).to eq quantity

            expect(upcoming.lines.data[1].proration).to be_falsey
            expect(upcoming.lines.data[1].plan.id).to eq '100y'
            expect(upcoming.lines.data[1].amount).to eq with_trial ? 0 : 20000
            expect(upcoming.lines.data[1].quantity).to eq new_quantity
          end

          # after { new_monthly_plan.delete rescue nil if @teardown_monthly_plan }
          # after { new_yearly_plan.delete rescue nil if @teardown_yearly_plan }
        end
      end

      shared_examples 'no proration is done' do
        it 'generates a preview without performing an actual proration', live: true do
          expect(preview.subtotal).to eq 150_00
          # this is a future invoice (generted at the end of the current subscription cycle), rather than a proration invoice
          expect(preview.due_date).to be_nil
          expect(preview.period_start).to eq subscription.current_period_start
          expect(preview.period_end).to eq subscription.current_period_end
          expect(preview.lines.count).to eq 1
          line = preview.lines.first
          expect(line.type).to eq 'subscription'
          expect(line.amount).to eq 150_00
          # line period is for the NEXT subscription cycle
          expect(line.period.start).to be_within(1).of subscription.current_period_end
          expect(Time.at(line.period.end).month).to be_within(1).of (Time.at(subscription.current_period_end).to_datetime >> 1).month # +1 month
        end
      end

      describe 'upcoming invoice with no proration parameters specified' do
        let(:preview) do
          Stripe::Invoice.upcoming(
              customer: customer.id,
              subscription: subscription.id
          )
        end

        it_behaves_like 'no proration is done'
      end

      describe 'upcoming invoice with same subscription plan and quantity specified' do
        let(:preview) do
          proration_date = Time.now + 60
          Stripe::Invoice.upcoming(
              customer: customer.id,
              subscription: subscription.id,
              subscription_plan: plan.id,
              subscription_quantity: quantity,
              subscription_proration_date: proration_date.to_i,
              subscription_trial_end: nil
          )
        end

        it_behaves_like 'no proration is done'
      end
    end

    it 'sets the start and end of billing periods correctly when plan has an interval_count' do
      @oddplan = stripe_helper.create_plan(product: product.id, interval: "week", interval_count: 11, id: "weekly_pl")
      @subscription = Stripe::Subscription.create(plan: @oddplan.id, customer: customer.id)
      @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

      expect(@upcoming.period_start + 6652800).to eq(@upcoming.period_end) # 6652800 = +11 weeks
      expect(@upcoming.period_end).to eq(@upcoming.lines.data[0].period.start)
      expect(@upcoming.period_end + 6652800).to eq(@upcoming.lines.data[0].period.end) # 6652800 = +11 weeks
      expect(@upcoming.next_payment_attempt).to eq(@upcoming.period_end + 3600) # +1 hour
    end

    it 'chooses the most recent of multiple subscriptions' do
      @shortplan = stripe_helper.create_plan(id: 'a', product: product.id, interval: "week") # 1 week sub
      @plainplan = stripe_helper.create_plan(id: 'b', product: product.id, interval: "month") # 1 month sub
      @longplan  = stripe_helper.create_plan(id: 'c', product: product.id, interval: "year") # 1 year sub

      @plainsub = Stripe::Subscription.create(plan: @plainplan.id, customer: customer.id)
      @shortsub = Stripe::Subscription.create(plan: @shortplan.id, customer: customer.id)
      @longsub  = Stripe::Subscription.create(plan: @longplan.id, customer: customer.id)

      @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

      expect(@upcoming.period_start + 604800).to eq(@upcoming.period_end) # 604800 = 1 week
      expect(@upcoming.period_end + 604800).to eq(@upcoming.lines.data[0].period.end) # 604800 = 1 week
      expect(@upcoming.subscription).to eq(@shortsub.id)
    end

    it 'does not store the stripe invoice in memory since its only a preview', with_subscription: true do
      invoice = Stripe::Invoice.upcoming(customer: customer.id)
      data = test_data_source(:invoices)
      expect(data[invoice.id]).to be_nil
    end

    context 'retrieving invoice line items' do
      it 'returns all line items for created invoice' do
        invoice = Stripe::Invoice.create(customer: customer.id)
        line_items = invoice.lines.list

        expect(invoice).to be_a Stripe::Invoice
        expect(line_items.count).to eq(1)
        expect(line_items.data[0].object).to eq('line_item')
        expect(line_items.data[0].description).to eq('Test invoice item')
        expect(line_items.data[0].type).to eq('invoiceitem')
      end

      it 'returns all line items for upcoming invoice' do
        plan = stripe_helper.create_plan(product: product.id, id: "silver_pl")
        subscription = Stripe::Subscription.create(plan: plan.id, customer: customer.id)
        upcoming = Stripe::Invoice.upcoming(customer: customer.id)
        line_items = upcoming.lines

        expect(upcoming).to be_a Stripe::Invoice
        expect(line_items.count).to eq(1)
        expect(line_items.data[0].object).to eq('line_item')
        expect(line_items.data[0].description).to eq('Test invoice item')
        expect(line_items.data[0].type).to eq('subscription')
      end
    end

    context 'calculates month and year offsets correctly' do

      it 'for one month plan on the 1st' do
        @plan = stripe_helper.create_plan(product: product.id, id: "one_mo_plan")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2014,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,1,12))
      end

      it 'for one year plan on the 1st' do
        @plan = stripe_helper.create_plan(interval: "year", product: product.id, id: "year_plan")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2012,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,1,1,12))
      end

      it 'for one month plan on the 31st' do
        @plan = stripe_helper.create_plan(product: product.id, id: "one_mo_plan")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2014,1,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,31,12))
      end

      it 'for one year plan on feb. 29th' do
        @plan = stripe_helper.create_plan(product: product.id, interval: "year", id: "year_plan")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2012,2,29,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,2,29,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,2,28,12))
      end

      it 'for two month plan on dec. 31st' do
        @plan = stripe_helper.create_plan(product: product.id, interval_count: 2, id: 'two_mo_plan')
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2013,12,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,12,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 4,30,12))
      end

      it 'for three month plan on nov. 30th' do
        @plan = stripe_helper.create_plan(product: product.id, interval_count: 3)
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: customer.id, current_period_start: Time.utc(2013,11,30,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,11,30,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 5,30,12))
      end
    end

  end
end
