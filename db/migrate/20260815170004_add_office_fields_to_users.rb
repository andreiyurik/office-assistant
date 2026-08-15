class AddOfficeFieldsToUsers < ActiveRecord::Migration[8.1]
  # SQLite refuses to add a NOT NULL column to an existing table without a
  # default value, so these stay nullable in the database and are required by
  # the User model instead.
  def change
    add_column :users, :name, :string
    add_reference :users, :team, foreign_key: true
    add_reference :users, :default_desk, foreign_key: { to_table: :resources }
  end
end
