class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh,   presence: true
  validates :auth,     presence: true
end
