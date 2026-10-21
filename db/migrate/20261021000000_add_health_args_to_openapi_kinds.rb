# frozen_string_literal: true

class AddHealthArgsToOpenapiKinds < ActiveRecord::Migration[8.1]
  def change
    # Optional arguments passed to the kind's `health_op` when the "Test
    # connection" probe runs. Lets a preset supply values a health operation
    # requires but the probe can't infer — e.g. Gmail's `getProfile` needs a
    # path `userId` (`me` for the authenticated user).
    add_column :openapi_kinds, :health_args, :json, default: {}
  end
end
