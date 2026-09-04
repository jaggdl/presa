# frozen_string_literal: true

class AddCategoryAndVersionsToOpenapiKinds < ActiveRecord::Migration[8.1]
  def change
    add_column :openapi_kinds, :category, :string, default: "general", null: false
  end
end
