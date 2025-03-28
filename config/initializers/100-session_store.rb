Rails.application.config.session_store(
  :discourse_cookie_store,
  key: "_forum_session",
  path: Rails.application.config.relative_url_root || "/",
  domain: :all,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax 
)