# frozen_string_literal: true

Rails.application.config.web_push = ActiveSupport::OrderedOptions.new.tap do |config|
  config.vapid_public_key  = Rails.application.credentials.dig(:web_push, :vapid_public_key)
  config.vapid_private_key = Rails.application.credentials.dig(:web_push, :vapid_private_key)
  config.vapid_subject     = Rails.application.credentials.dig(:web_push, :vapid_subject) || "mailto:webpush@example.com"
end
