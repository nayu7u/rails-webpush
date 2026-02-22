# frozen_string_literal: true

require "test_helper"

class SendWebPushNotificationJobTest < ActiveJob::TestCase
  setup do
    @subscription = PushSubscription.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test-job-#{SecureRandom.hex(8)}",
      p256dh:   "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8p8REfXRs=",
      auth:     "tBHItJI5svbpC7-BM3YKxQ=="
    )
    @payload = { title: "Test", body: "Hello", icon: "/icon.png", data: { path: "/" } }

    # Save original payload_send so we can restore it
    @original_payload_send = WebPush.method(:payload_send)
  end

  teardown do
    # Restore original method
    original = @original_payload_send
    WebPush.define_singleton_method(:payload_send) { |**args| original.call(**args) }
  end

  test "job is enqueued" do
    assert_enqueued_with(job: SendWebPushNotificationJob) do
      SendWebPushNotificationJob.perform_later(payload: @payload)
    end
  end

  test "sends to specific subscription" do
    calls = []
    WebPush.define_singleton_method(:payload_send) { |**args| calls << args }

    assert_nothing_raised do
      SendWebPushNotificationJob.perform_now(
        push_subscription_id: @subscription.id,
        payload: @payload
      )
    end
    assert_equal 1, calls.size
  end

  test "sends to all subscriptions when no id specified" do
    calls = []
    WebPush.define_singleton_method(:payload_send) { |**args| calls << args }

    SendWebPushNotificationJob.perform_now(payload: @payload)
    assert_equal PushSubscription.count, calls.size
  end

  test "removes subscription on ExpiredSubscription error" do
    response = Object.new
    response.define_singleton_method(:code) { "410" }
    response.define_singleton_method(:body) { "" }

    WebPush.define_singleton_method(:payload_send) { |**_args| raise WebPush::ExpiredSubscription.new(response, "localhost") }

    assert_difference "PushSubscription.count", -1 do
      SendWebPushNotificationJob.perform_now(
        push_subscription_id: @subscription.id,
        payload: @payload
      )
    end
  end

  test "removes subscription on InvalidSubscription error" do
    response = Object.new
    response.define_singleton_method(:code) { "404" }
    response.define_singleton_method(:body) { "" }

    WebPush.define_singleton_method(:payload_send) { |**_args| raise WebPush::InvalidSubscription.new(response, "localhost") }

    assert_difference "PushSubscription.count", -1 do
      SendWebPushNotificationJob.perform_now(
        push_subscription_id: @subscription.id,
        payload: @payload
      )
    end
  end
end
