# frozen_string_literal: true

class NotificationsController < ApplicationController
  # POST /notifications
  def create
    count = PushSubscription.count

    if count.zero?
      redirect_to root_path, alert: "No subscriptions found."
      return
    end

    SendWebPushNotificationJob.perform_later(
      payload: {
        title: "Hello from Rails! 🚀",
        body:  "This is a test push notification sent at #{Time.current.strftime('%H:%M:%S')}.",
        icon:  "/icon.png",
        data:  { path: "/" }
      }
    )

    redirect_to root_path, notice: "Push notification queued for #{count} subscriber(s)."
  end
end
