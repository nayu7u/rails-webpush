require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  setup do
    @valid_attrs = {
      endpoint:   "https://fcm.googleapis.com/fcm/send/test-endpoint-123",
      p256dh:     "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8p8REfXRs=",
      auth:       "tBHItJI5svbpC7-BM3YKxQ==",
      user_agent: "TestBrowser/1.0"
    }
  end

  test "valid subscription is saved" do
    sub = PushSubscription.new(@valid_attrs)
    assert sub.valid?
    assert sub.save
  end

  test "endpoint is required" do
    sub = PushSubscription.new(@valid_attrs.merge(endpoint: nil))
    assert_not sub.valid?
    assert_includes sub.errors[:endpoint], "can't be blank"
  end

  test "p256dh is required" do
    sub = PushSubscription.new(@valid_attrs.merge(p256dh: nil))
    assert_not sub.valid?
    assert_includes sub.errors[:p256dh], "can't be blank"
  end

  test "auth is required" do
    sub = PushSubscription.new(@valid_attrs.merge(auth: nil))
    assert_not sub.valid?
    assert_includes sub.errors[:auth], "can't be blank"
  end

  test "endpoint must be unique" do
    PushSubscription.create!(@valid_attrs)
    duplicate = PushSubscription.new(@valid_attrs)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], "has already been taken"
  end

  test "user_agent is optional" do
    sub = PushSubscription.new(@valid_attrs.merge(user_agent: nil))
    assert sub.valid?
  end
end
