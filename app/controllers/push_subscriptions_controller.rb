# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  skip_forgery_protection only: %i[create destroy]

  # POST /push_subscriptions
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    subscription.assign_attributes(subscription_params)

    if subscription.save
      render json: { message: "Subscription registered" }, status: :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /push_subscriptions
  def destroy
    subscription = PushSubscription.find_by(endpoint: params[:endpoint])

    if subscription&.destroy
      render json: { message: "Subscription removed" }, status: :ok
    else
      render json: { message: "Subscription not found" }, status: :not_found
    end
  end

  private

  def subscription_params
    params.expect(subscription: [ :endpoint, :p256dh, :auth, :user_agent ])
  end
end
