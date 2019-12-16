class CreateSearchWords < ActiveRecord::Migration[6.0]
  def change
    create_table :search_words do |t|
      t.string :channel_id, null: false, limit: 64
      t.text :keyword, null: false
      t.integer :since_id, limit: 8, default: 0, null: false

      t.timestamps null: false
    end
    add_index :search_words, :channel_id, unique: true
  end
end
