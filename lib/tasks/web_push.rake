# frozen_string_literal: true

namespace :web_push do
  desc "Send a test push notification to all subscribers"
  task :test, [ :title, :body ] => :environment do |_t, args|
    title = args[:title] || "Test Notification"
    body  = args[:body]  || "This is a test push from Rails 🚀"

    count = PushSubscription.count
    if count.zero?
      puts "No push subscriptions found. Subscribe from the home page first."
      next
    end

    puts "Sending push notification to #{count} subscription(s)…"

    SendWebPushNotificationJob.perform_later(
      payload: {
        title: title,
        body:  body,
        icon:  "/icon.png",
        data:  { path: "/" }
      }
    )

    puts "Job enqueued. Run `bin/jobs` or Solid Queue to process."
  end
end
