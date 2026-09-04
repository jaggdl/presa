#!/usr/bin/env ruby
# Measures one or more opencode sessions and appends them to the registry
# metrics CSV, keyed to the current checkout's HEAD commit + branch.
#
# Usage:
#   ruby append_metrics.rb <run_id> <sessionID> [<sessionID> ...]
#   cat ids.txt | ruby append_metrics.rb <run_id>
#
# Pairs with measure_sessions.rb (same dir). This script:
#   1. runs measure_sessions.rb --csv <ids> to get the measured fields
#   2. prepends measured_at (UTC now), run_id, commit (git rev-parse HEAD),
#      branch (git branch --show-current) to each row
#   3. appends rows to .opencode/metrics/registry-task-metrics.csv,
#      creating dir + header on first run
#
# Env overrides:
#   METRICS_CSV=/path/to.csv   use an alternate CSV path
#   MEASURE=gem|ruby           (default) which ruby to run the measurement with

require "open3"
require "securerandom"

CSV_REL = ENV["METRICS_CSV"] || File.join(".opencode", "metrics", "registry-task-metrics.csv")
HEADER = %i[
  measured_at run_id commit branch session agent model cost
  tokens_in tokens_out tokens_reasoning cache_read cache_write
  duration_sec in_chars out_chars
].freeze

run_id = ARGV.shift
abort "usage: append_metrics.rb <run_id> <sessionID...>   (or session IDs on stdin)" unless run_id
ids = ARGV
ids = STDIN.read.split(/\s+/).reject(&:empty?) if ids.empty?
abort "no session IDs given" if ids.empty?

# Locate sibling measure script.
script_dir = File.expand_path(__dir__)
measure_script = File.join(script_dir, "measure_sessions.rb")
abort "missing #{measure_script}" unless File.exist?(measure_script)

# Capture commit/branch from cwd (must be inside the repo checkout).
commit = `git rev-parse HEAD 2>/dev/null`.strip
branch = `git branch --show-current 2>/dev/null`.strip
abort "not inside a git repo (cannot key rows to a commit)" if commit.empty?
measured_at = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

# Measure.
stdout, stderr, status = Open3.capture3("ruby", measure_script, "--csv", *ids)
abort "measure_sessions.rb failed: #{stderr}" unless status.success?

lines = stdout.lines.map(&:strip).reject(&:empty?)
abort "measure_sessions.rb returned no rows" if lines.empty?
measure_header = lines.shift
if measure_header.split(",").first != "session"
  lines.unshift(measure_header) # unexpected format; keep everything verbatim
end

# Column order sanity: measured output must align with HEADER after the 4
# prepended fields (measured_at, run_id, commit, branch).
expected_tail = HEADER.drop(4).join(",")
unless measure_header.end_with?(expected_tail)
  warn "WARNING: measure header mismatch:\n  got:  #{measure_header}\n  want tail: #{expected_tail}"
end

# Append to CSV.
csv_path = File.expand_path(CSV_REL)
require "fileutils"
FileUtils.mkdir_p(File.dirname(csv_path))
new_file = !File.exist?(csv_path)
File.open(csv_path, "a") do |f|
  f.puts(HEADER.join(",")) if new_file
  lines.each do |row|
    f.puts([measured_at, run_id, commit, branch, row].join(","))
  end
end

puts "appended #{lines.size} row(s) to #{csv_path} (run #{run_id} @ #{commit})"