# frozen_string_literal: true

module SpotifyPlayer
  # Start a new context or resume current playback on the user's active
  # device. Requires Spotify Premium.
  class StartResumePlaybackTool < Base
    description "Start a new context or resume current playback on the user's active device (Premium)"

    arguments do
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
      optional(:context_uri).filled(:string).description("Spotify URI of the context to play (album, artist, or playlist)")
      optional(:uris).array(:str?).description("A list of Spotify track URIs to play")
      optional(:position).filled(:integer, gteq?: 0).description("Zero-based position in the context at which to start (use with context_uri)")
      optional(:uri).filled(:string).description("Spotify URI of the item in the context at which to start (use with context_uri)")
      optional(:position_ms).filled(:integer, gteq?: 0).description("The position in milliseconds to start from")
    end

    def call(device_id: nil, context_uri: nil, uris: nil, position: nil, uri: nil, position_ms: nil)
      params = {}
      params[:device_id] = device_id if device_id
      body = {}
      body[:context_uri] = context_uri if context_uri
      body[:uris] = uris if uris&.any?
      body[:offset] = { position: position } if !position.nil?
      body[:offset] = { uri: uri } if uri
      body[:position_ms] = position_ms if !position_ms.nil?
      spotify_put("me/player/play", params: params, body: body.presence)
    end
  end
end
