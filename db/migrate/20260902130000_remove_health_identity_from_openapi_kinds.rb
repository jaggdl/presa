# frozen_string_literal: true

class RemoveHealthIdentityFromOpenapiKinds < ActiveRecord::Migration[8.1]
  def change
    remove_column :openapi_kinds, :health_identity, :string
  end
end
