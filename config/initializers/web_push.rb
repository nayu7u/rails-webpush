# frozen_string_literal: true

Rails.application.config.web_push = ActiveSupport::OrderedOptions.new.tap do |config|
  credential_value = lambda do |key|
    Rails.application.credentials.dig(:web_push, key)
  rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  config.vapid_public_key  = ENV["VAPID_PUBLIC_KEY"].presence || credential_value.call(:vapid_public_key)
  config.vapid_private_key = ENV["VAPID_PRIVATE_KEY"].presence || credential_value.call(:vapid_private_key)
  config.vapid_subject     = ENV["VAPID_SUBJECT"].presence || credential_value.call(:vapid_subject) || "mailto:webpush@example.com"

  if Rails.env.production? && (config.vapid_public_key.blank? || config.vapid_private_key.blank?)
    raise "Missing VAPID keys for Web Push. Please set web_push.vapid_public_key and web_push.vapid_private_key in Rails credentials."
  end
end
