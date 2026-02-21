# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders home page with vapid key" do
    get root_path
    assert_response :success
    assert_select "[data-push-subscription-vapid-public-key-value]"
  end
end
