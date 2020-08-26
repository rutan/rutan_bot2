class CreateYoutubeChannels < ActiveRecord::Migration[6.0]
  def change
    create_table :youtube_channels do |t|
      t.string :title, null: false, limit: 255
      t.string :youtube_channel_id, null: false, limit: 255
      t.integer :subscriber_count, limit: 8, default: 0, null: false
      t.integer :view_count, limit: 8, default: 0, null: false
      t.string :post_channel_id, null: false, limit: 64

      t.timestamps null: false
    end
    add_index :youtube_channels, [:youtube_channel_id, :post_channel_id], unique: true, name: 'index_youtube_channels_on_ycid_and_pcid'
  end
end
