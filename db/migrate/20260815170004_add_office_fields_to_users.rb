class AddOfficeFieldsToUsers < ActiveRecord::Migration[8.1]
  # Added to a table that already has rows, so they start nullable;
  # RequireTeamAndNameForUsers tightens name and team_id once the seeds fill
  # them in. default_desk stays optional on purpose: not everyone has one.
  def change
    add_column :users, :name, :string
    add_reference :users, :team, foreign_key: true
    add_reference :users, :default_desk, foreign_key: { to_table: :resources }
  end
end
