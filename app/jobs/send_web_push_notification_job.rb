# frozen_string_literal: true

class SendWebPushNotificationJob < ApplicationJob
  queue_as :default

  # payload: { title: "...", body: "...", icon: "/icon.png", data: { path: "/" } }
  def perform(push_subscription_id: nil, payload: {})
    subscriptions = if push_subscription_id
      PushSubscription.where(id: push_subscription_id)
    else
      PushSubscription.all
    end

    vapid = Rails.application.config.web_push

    subscriptions.find_each do |sub|
      WebPush.payload_send(
        message:      payload.to_json,
        endpoint:     sub.endpoint,
        p256dh:       sub.p256dh,
        auth:         sub.auth,
        vapid: {
          public_key:  vapid.vapid_public_key,
          private_key: vapid.vapid_private_key,
          subject:     vapid.vapid_subject
        },
        ssl_timeout: 5,
        open_timeout: 5,
        read_timeout: 5
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      Rails.logger.info { "Removing expired/invalid push subscription ##{sub.id}" }
      sub.destroy
    rescue WebPush::ResponseError => e
      Rails.logger.warn { "WebPush failed for subscription ##{sub.id}: #{e.message}" }
    end
  end
end
