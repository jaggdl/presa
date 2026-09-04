#!/usr/bin/env ruby
# Measures opencode session usage. Primary source is the opencode SQLite DB
# (`opencode db path`) which also carries agent name, model, cost, and
# duration; falls back to `opencode export <id>` for sessions not in the DB.
#
# Usage:
#   ruby measure_sessions.rb [--csv] <sessionID> [<sessionID> ...]
#   cat ids.txt | ruby measure_sessions.rb [--csv]
#
# Fields: session, agent, model, cost, tokens_in, tokens_out, tokens_reasoning,
#         cache_read, cache_write, duration_sec, in_chars, out_chars
# (in_chars/out_chars are ~3 chars per token estimates)

require "json"

CSV = ARGV.delete("--csv")

class SessionMeasure
  attr_reader :id

  ROW_KEYS = %i[
    session agent model cost tokens_in tokens_out tokens_reasoning
    cache_read cache_write duration_sec in_chars out_chars
  ].freeze

  def initialize(id)
    @id = id
  end

  def measure
    row = {}
    row[:session] = @id

    info = db_lookup || export_info
    if info[:tokens]
      row[:tokens_in]          = info[:tokens][:input] || 0
      row[:tokens_out]         = info[:tokens][:output] || 0
      row[:tokens_reasoning]   = info[:tokens][:reasoning] || 0
      row[:cache_read]         = info.dig(:tokens, :cache, :read) || 0
      row[:cache_write]        = info.dig(:tokens, :cache, :write) || 0
      row[:in_chars]           = row[:tokens_in] * 3
      row[:out_chars]          = row[:tokens_out] * 3
    elsif info[:export_tokens]
      t = info[:export_tokens]
      row[:tokens_in]          = t["input"] || 0
      row[:tokens_out]         = t["output"] || 0
      row[:tokens_reasoning]   = t["reasoning"] || 0
      row[:cache_read]         = t.dig("cache", "read") || 0
      row[:cache_write]        = t.dig("cache", "write") || 0
      row[:in_chars]           = row[:tokens_in] * 3
      row[:out_chars]          = row[:tokens_out] * 3
    end

    %i[agent model cost duration_sec].each do |k|
      row[k] = info[k] if info[k]
    end

    row
  end

  private

  # --- opencode DB (primary) ------------------------------------------------

  def db_path
    @db_path ||= begin
      path = `opencode db path`.strip
      File.exist?(path) ? path : nil
    rescue StandardError
      nil
    end
  end

  def db_lookup
    return nil unless db_path

    query = <<~SQL
      SELECT id, agent, model, cost,
             tokens_input, tokens_output, tokens_reasoning,
             tokens_cache_read, tokens_cache_write,
             time_created, time_updated
      FROM session WHERE id = '#{id}'
    SQL
    out = `sqlite3 -json "#{db_path}" "#{query.gsub('"', '""')}"`.strip
    rows = JSON.parse(out)
    return nil if rows.empty?

    r = rows.first
    model = begin
      JSON.parse(r["model"] || "null")
    rescue JSON::ParserError
      nil
    end

    {
      agent: r["agent"],
      model: model&.dig("id"),
      cost: r["cost"],
      tokens: {
        input: r["tokens_input"],
        output: r["tokens_output"],
        reasoning: r["tokens_reasoning"],
        cache: {
          read: r["tokens_cache_read"],
          write: r["tokens_cache_write"]
        }
      },
      duration_sec: ((r["time_updated"].to_i - r["time_created"].to_i) / 1000.0).round
    }
  rescue JSON::ParserError, StandardError
    nil
  end

  # --- opencode export (fallback) -------------------------------------------

  def export_info
    require "tempfile"
    file = Tempfile.new("opencode-session")
    raw = begin
      system("opencode", "export", id, out: file.path, err: File::NULL)
      file.rewind
      file.read
    ensure
      file.close!
    end
    return {} unless $?.success?

    json_start = raw.index(/\{/)
    parsed = JSON.parse(raw[json_start..])
    info = parsed["info"]
    {
      export_tokens: info["tokens"],
      duration_sec: info.dig("time") &&
        ((info.dig("time", "updated").to_i - info.dig("time", "created").to_i) / 1000.0).round,
      export_title: info["title"]
    }
  rescue StandardError
    {}
  end
end

ids = ARGV.dup
if ids.empty?
  ids = STDIN.read.split(/\s+/).reject(&:empty?)
end

rows = ids.map { |id| SessionMeasure.new(id).measure }

if CSV
  header = SessionMeasure::ROW_KEYS
  quoted = ->(v) { v.to_s.include?(",") || v.to_s.include?('"') ? "\"#{v.to_s.gsub('"', '""')}\"" : v.to_s }
  puts header.join(",")
  rows.each do |r|
    puts header.map { |k| quoted.call(r[k]) }.join(",")
  end
else
  display = %i[session agent model cost tokens_in tokens_out tokens_reasoning cache_read duration_sec]
  widths = display.map { |k| [k.to_s.length] }
  rows.each do |r|
    display.each_with_index { |k, i| widths[i] << r[k].to_s.length }
  end
  widths.map!(&:max)

  fmt = ->(r) { display.each_with_index.map { |k, i| r[k].to_s.ljust(widths[i]) }.join("  ") }
  puts display.map(&:to_s).each_with_index.map { |h, i| h.ljust(widths[i]) }.join("  ")
  rows.each { |r| puts fmt.call(r) }
end
