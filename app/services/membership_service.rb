class MembershipService
  attr_reader :customer, :user, :monthly_dues, :subscription, :plan

  def initialize(customer, user, monthly_dues)
    @customer = customer
    @user = user
    @monthly_dues = monthly_dues || @user.monthly_dues
    @plan = find_or_create_plan
    @subscription = find_subscription
  end

  def subscribe_customer
    true if create_subscription &&
        assign_membership_role &&
        user.update(monthly_dues: monthly_dues,
                    membership_started_at: Time.current,
                    email_membership_newsletter: true,
                    stripe_id_code: customer.id) &&
        send_welcome_email
  end

  def update_subscription
    true if update_stripe_plan_for_subscription &&
        assign_membership_role &&
        user.update(monthly_dues: monthly_dues) &&
        send_update_email
  end

  def unsubscribe_customer
    true if cancel_subscription &&
        remove_all_membership_roles &&
        user.update(monthly_dues: 0, email_membership_newsletter: false) &&
        send_cancellation_email
  end

  def find_subscription
    customer.subscriptions.first || nil
  end

  def create_subscription
    customer.subscriptions.create(plan: plan.id)
  end

  def cancel_subscription
    subscription.delete
  end

  def update_stripe_plan_for_subscription
    subscription.items = [{
      id: subscription.items.data[0].id,
      plan: plan.id
    }]
    subscription.save
  end

  def find_or_create_plan
    Stripe::Plan.retrieve("membership-#{monthly_dues}")
    # Using rescue because not finding a plan errors out instead returning of nil
  rescue Stripe::InvalidRequestError
    Stripe::Plan.create(
      id: "membership-#{monthly_dues}",
      currency: "usd",
      interval: "month",
      name: "Monthly DEV Membership",
      amount: monthly_dues,
      statement_descriptor: "DEV membership",
    )
  end

  def assign_membership_role
    # change role names here, in role.rb, users_controller#handle_settings_tab => @membership_names
    remove_all_membership_roles
    user.add_role :analytics_beta_tester
    if monthly_dues >= 100000
      user.add_role :triple_unicorn_member
    elsif monthly_dues > 2500
      user.add_role :level_4_member
    elsif monthly_dues == 2500
      user.add_role :level_3_member
    elsif monthly_dues.between?(1000, 2499)
      user.add_role :level_2_member
    else
      user.add_role :level_1_member
    end
  end

  def remove_all_membership_roles
    tiers = %i[ triple_unicorn_member level_4_member level_3_member level_2_member level_1_member
                analytics_beta_tester]
    tiers.each { |t| user.remove_role(t) }
  end

  def send_welcome_email
    MembershipMailer.delay.new_membership_subscription_email(user, user.roles.last.name)
  end

  def send_update_email
    MembershipMailer.delay.subscription_update_confirm_email(user)
  end

  def send_cancellation_email
    MembershipMailer.delay.subscription_cancellation_email(user)
  end
end
