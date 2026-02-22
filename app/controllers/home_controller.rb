# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @vapid_public_key = Rails.application.config.web_push.vapid_public_key
  end
end
