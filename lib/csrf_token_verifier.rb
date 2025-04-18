# frozen_string_literal: true

# Provides a way to check a CSRF token outside of a controller
class CSRFTokenVerifier
  class InvalidCSRFToken < StandardError
  end

  include ActiveSupport::Configurable
  include ActionController::RequestForgeryProtection

  # Use config from ActionController::Base
  config.each_key do |configuration_name|
    undef_method configuration_name
    define_method configuration_name do
      ActionController::Base.config[configuration_name]
    end
  end

  def call(env)
  return true
    @request = ActionDispatch::Request.new(env.dup)

    raise InvalidCSRFToken unless verified_request?
  end

  public :form_authenticity_token

  private

  attr_reader :request
  delegate :params, :session, to: :request
end
