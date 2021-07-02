class CreateTwitterProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :twitter_profiles do |t|
      t.string :screen_name, null: false, limit: 255
      t.integer :twitter_user_id, limit: 8, null: false
      t.integer :followers_count, limit: 8, default: 0, null: false
      t.integer :friends_count, limit: 8, default: 0, null: false
      t.integer :statuses_count, limit: 8, default: 0, null: false
      t.string :post_channel_id, null: false, limit: 64

      t.timestamps null: false
    end
    add_index :twitter_profiles, [:twitter_user_id, :post_channel_id], unique: true, name: 'index_twitter_profiles_on_tuid_and_pcid'
  end
end
