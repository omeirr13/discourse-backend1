# frozen_string_literal: true

# name: custom-redirect
# about: Custom redirect plugin
# version: 0.1
# authors: Omeir Mujtaba

enabled_site_setting :custom_redirect_enabled

after_initialize do
    on(:after_authenticate) do |authenticator, user, session_data|
        Rails.logger.debug("Session Data 123 Before, #{session_data}")
        
        session_data[:destination_url] = "http://localhost:4200"
        Rails.logger.debug("Session Data 123 After, #{session_data}")
    end
end
