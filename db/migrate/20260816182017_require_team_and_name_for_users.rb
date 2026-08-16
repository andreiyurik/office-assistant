class RequireTeamAndNameForUsers < ActiveRecord::Migration[8.1]
  # The model has required both since office fields were added to users; the
  # database said nothing, so a person without a team could be created from the
  # console and every page would break on their team's zone.
  def change
    change_column_null :users, :name, false
    change_column_null :users, :team_id, false
  end
end
