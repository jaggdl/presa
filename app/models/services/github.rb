module Services
  class Github < Service
    kind :github

    config_field :api_token, required: true, secret: true
    config_field :base_url, default: "https://api.github.com"
  end
end