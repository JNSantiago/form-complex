class AddCollumnKindToUser < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :kind, foreign_key: true
  end
end
