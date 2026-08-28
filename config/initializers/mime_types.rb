# frozen_string_literal: true

# MIME type for the bundled agent client/installer shell scripts so the bot
# tool views can be rendered as text/x-sh (format :sh).
Mime::Type.register "text/x-sh", :sh
