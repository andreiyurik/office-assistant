class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string :kind, null: false
      t.string :name, null: false
      t.references :zone, null: false, foreign_key: true
      t.integer :capacity
      t.integer :grid_row
      t.integer :grid_col

      t.timestamps
    end

    add_index :resources, :kind

    # Two desks cannot occupy the same cell of the floor map.
    add_index :resources, [ :grid_row, :grid_col ],
      unique: true,
      where: "kind = 'desk'",
      name: "index_desks_on_grid_cell"
  end
end
