# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "POST /notification redirects with alert when no subscriptions" do
    PushSubscription.delete_all
    post notification_path
    assert_redirected_to root_path
    assert_equal "No subscriptions found.", flash[:alert]
  end

  test "POST /notification enqueues job and redirects with notice" do
    PushSubscription.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/notif-test-#{SecureRandom.hex(8)}",
      p256dh:   "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8p8REfXRs=",
      auth:     "tBHItJI5svbpC7-BM3YKxQ=="
    )

    assert_enqueued_with(job: SendWebPushNotificationJob) do
      post notification_path
    end

    assert_redirected_to root_path
    assert_match(/queued/, flash[:notice])
  end
end
