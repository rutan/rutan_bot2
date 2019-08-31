class CreateCheerings < ActiveRecord::Migration[6.0]
  def change
    create_table :cheerings do |t|
      t.string :emoji, null: false
      t.string :name, null: false, limit: 64
      t.text :text, null: false

      t.timestamps null: false
    end
    add_index :cheerings, :emoji, unique: true
  end
end
