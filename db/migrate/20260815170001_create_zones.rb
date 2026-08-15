class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.string :name, null: false
      t.integer :floor, null: false

      t.timestamps
    end
  end
end
