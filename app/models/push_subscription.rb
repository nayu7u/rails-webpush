# frozen_string_literal: true

require "base64"

class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh,   presence: true
  validates :auth,     presence: true

  validate :endpoint_must_be_valid_https_url
  validate :p256dh_must_be_base64
  validate :auth_must_be_base64

  private

  def endpoint_must_be_valid_https_url
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    return if uri.is_a?(URI::HTTPS) && uri.host.present?

    errors.add(:endpoint, "must be a valid HTTPS URL")
  rescue URI::InvalidURIError
    errors.add(:endpoint, "must be a valid HTTPS URL")
  end

  def p256dh_must_be_base64
    validate_base64_field(:p256dh)
  end

  def auth_must_be_base64
    validate_base64_field(:auth)
  end

  def validate_base64_field(attribute)
    value = public_send(attribute)
    return if value.blank?
    return if base64_encoded?(value)

    errors.add(attribute, "must be a valid Base64 string")
  end

  def base64_encoded?(value)
    normalized = value.tr("-_", "+/")
    padding = "=" * ((4 - (normalized.length % 4)) % 4)

    Base64.strict_decode64(normalized + padding)
    true
  rescue ArgumentError
    false
  end
end
