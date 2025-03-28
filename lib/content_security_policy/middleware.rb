  # frozen_string_literal: true
require "content_security_policy"

class ContentSecurityPolicy
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      user = User.find_by(id: env["HTTP_API_USERNAME"].to_i) # Use `find_by` to avoid exceptions

      if user
        env["HTTP_API_USERNAME"] = user.username
      end
      request = Rack::Request.new(env)
      _, headers, _ = response = @app.call(env)

      return response if headers["Content-Security-Policy"].present?
      return response unless html_response?(headers)

      # The EnforceHostname middleware ensures request.host_with_port can be trusted
      protocol = (SiteSetting.force_https || request.ssl?) ? "https://" : "http://"
      base_url = protocol + request.host_with_port + Discourse.base_path

      theme_id = env[:resolved_theme_id]

      headers["Content-Security-Policy"] = policy(
        theme_id,
        base_url: base_url,
        path_info: env["PATH_INFO"],
      ) if SiteSetting.content_security_policy
      headers["Content-Security-Policy-Report-Only"] = policy(
        theme_id,
        base_url: base_url,
        path_info: env["PATH_INFO"],
      ) if SiteSetting.content_security_policy_report_only

      response
    end

    private

    delegate :policy, to: :ContentSecurityPolicy

    def html_response?(headers)
      headers["Content-Type"] && headers["Content-Type"] =~ /html/
    end
  end
end
