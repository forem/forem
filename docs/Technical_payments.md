## Payments

We use stripe because it's the industry leader in API-driven payment processing. It is developer-friendly and has good docs.

- [Stripe Rails Checkout](https://stripe.com/docs/checkout/rails)
- [Stripe Ruby API](https://stripe.com/docs/api?lang=ruby)

High level things we need to build:
  - The checkouts controller
  - A charges model to capture the transaction info in our database and keep track of what's been paid and when.
  - Mapping our user to a Stripe customer when payment is made
  - A page for a form (within the flow, we might want to pop the form in elsewhere, but we should have a dedicated generic page to create charges from.)

Before an article is saved, we check if there has been a charges made on it in the past week, and mark it as paid. Only "paid" posts show up on [/jobs](https://dev.to/jobs). And paying buys you one week, after which it goes back to unpaid. You can either make a new charges, which will bump it, or create a new article if you like.

Let's focus on creating a safe, well thought out checkout flow and really learn the Stripe API because it will be key to our flow. There will come other times where we will want to create charges, so we don't want to couple anything too tightly to the job flow.

## Technical details as I see them now:
  - charges controller as instructed
  - charges model in our database which map to Stripe charges, belongs to `Article` and `User`
    - Fields:
      - `user_id`
      - `article_id`
      - `stripe_charge_key`
  - A foreign key on our `User` model which maps to a Stripe customer
    - such as `stripe_customer_key`
  - A boolean field on our `Article` model called `paid`, which will be true if certain other criteria are met.

## User stories
  - I need to be able to create a job listing in a self serve manner as long as I have permission to do so and have it live as soon as I'm done
  - I need to be able to pay with a previously used card for convenience (cards can be retrieved from stripe via query, I don't think we need to store this in our DB since we have the `User` => `stripe_customer` mapping)

## Key takeaways
  - This is just my initial assertion, but let's not rush this process. I want to have a good dialogue about this and we should have several discussions about this implementation. And we should not go live without good test coverage around this flow.
  - The modeling of this problem is up for discussion. The above guideline is subject to change. I'd suggest diving deep into the docs.
  - This will also be how we accept payment for ads and other stuff. We're building towards that.

# You, Jess, are the head of finances, so this is your domain and you are perfect for this task!
