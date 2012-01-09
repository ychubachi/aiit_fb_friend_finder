class CreateHerokus < ActiveRecord::Migration
  def change
    create_table :herokus do |t|
      t.string :name
      t.integer :year

      t.timestamps
    end
  end
end
