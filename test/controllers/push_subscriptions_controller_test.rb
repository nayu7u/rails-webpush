# frozen_string_literal: true

require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription_params = {
      subscription: {
        endpoint:   "https://fcm.googleapis.com/fcm/send/test-#{SecureRandom.hex(8)}",
        p256dh:     "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8p8REfXRs=",
        auth:       "tBHItJI5svbpC7-BM3YKxQ==",
        user_agent: "TestBrowser/1.0"
      }
    }
  end

  test "POST /push_subscription creates a new subscription" do
    assert_difference "PushSubscription.count", 1 do
      post push_subscription_path, params: @subscription_params, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Subscription registered", json["message"]
  end

  test "POST /push_subscription with duplicate endpoint updates existing" do
    post push_subscription_path, params: @subscription_params, as: :json
    assert_response :created

    assert_no_difference "PushSubscription.count" do
      post push_subscription_path, params: @subscription_params, as: :json
    end
    assert_response :created
  end

  test "POST /push_subscription with missing data returns unprocessable_entity" do
    post push_subscription_path, params: { subscription: { endpoint: "" } }, as: :json
    assert_response :unprocessable_entity
  end

  test "DELETE /push_subscription removes subscription" do
    post push_subscription_path, params: @subscription_params, as: :json
    assert_response :created

    endpoint = @subscription_params[:subscription][:endpoint]

    assert_difference "PushSubscription.count", -1 do
      delete push_subscription_path, params: { endpoint: endpoint }, as: :json
    end
    assert_response :ok
  end

  test "DELETE /push_subscription with unknown endpoint returns not_found" do
    delete push_subscription_path, params: { endpoint: "https://unknown.example.com/nope" }, as: :json
    assert_response :not_found
  end
end
