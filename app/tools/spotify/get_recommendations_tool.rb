# frozen_string_literal: true

module Spotify
  # Recommended tracks generated from up to five seed artists, genres and/or
  # tracks, optionally tuned by target attribute values.
  class GetRecommendationsTool < Base
    description "Get recommendations generated from seed artists, genres or tracks, optionally tuned by target attribute values"

    arguments do
      optional(:seed_artists).array(:str?).description("A comma-separated list of Spotify IDs for seed artists. Up to 5 seed values total across seed_artists, seed_genres and seed_tracks")
      optional(:seed_genres).array(:str?).description("A comma-separated list of genres from the set of available genre seeds. Up to 5 seed values total across seed_artists, seed_genres and seed_tracks")
      optional(:seed_tracks).array(:str?).description("A comma-separated list of Spotify IDs for seed tracks. Up to 5 seed values total across seed_artists, seed_genres and seed_tracks")
      optional(:limit).filled(:integer, gteq?: 1, lteq?: 100).description("The target size of the list of recommended tracks (default 20, min 1, max 100)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
      optional(:target_acousticness).filled(:float, gteq?: 0, lteq?: 1).description("Target value for acousticness (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_danceability).filled(:float, gteq?: 0, lteq?: 1).description("Target value for danceability (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_energy).filled(:float, gteq?: 0, lteq?: 1).description("Target value for energy (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_instrumentalness).filled(:float, gteq?: 0, lteq?: 1).description("Target value for instrumentalness (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_liveness).filled(:float, gteq?: 0, lteq?: 1).description("Target value for liveness (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_loudness).filled(:float).description("Target value for loudness in decibels (dB); tracks nearest the target are preferred")
      optional(:target_speechiness).filled(:float, gteq?: 0, lteq?: 1).description("Target value for speechiness (0.0 to 1.0); tracks nearest the target are preferred")
      optional(:target_tempo).filled(:float).description("Target value for tempo in beats per minute (BPM); tracks nearest the target are preferred")
      optional(:target_valence).filled(:float, gteq?: 0, lteq?: 1).description("Target value for valence (0.0 to 1.0); tracks nearest the target are preferred")
    end

    def call(seed_artists: nil, seed_genres: nil, seed_tracks: nil, limit: nil, market: nil,
             target_acousticness: nil, target_danceability: nil, target_energy: nil,
             target_instrumentalness: nil, target_liveness: nil, target_loudness: nil,
             target_speechiness: nil, target_tempo: nil, target_valence: nil)
      params = {}
      params[:seed_artists] = seed_artists.join(",") if seed_artists
      params[:seed_genres] = seed_genres.join(",") if seed_genres
      params[:seed_tracks] = seed_tracks.join(",") if seed_tracks
      params[:limit] = limit if limit
      params[:market] = market if market
      params[:target_acousticness] = target_acousticness if target_acousticness
      params[:target_danceability] = target_danceability if target_danceability
      params[:target_energy] = target_energy if target_energy
      params[:target_instrumentalness] = target_instrumentalness if target_instrumentalness
      params[:target_liveness] = target_liveness if target_liveness
      params[:target_loudness] = target_loudness if target_loudness
      params[:target_speechiness] = target_speechiness if target_speechiness
      params[:target_tempo] = target_tempo if target_tempo
      params[:target_valence] = target_valence if target_valence
      spotify_get("recommendations", params: params)
    end
  end
end
