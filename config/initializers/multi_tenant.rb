Rails.application.configure do
  config.after_initialize do
    Team.multi_tenant = ENV["MULTI_TENANT"] == "true"
  end
end
