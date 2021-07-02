require 'cgi'
require 'json'
require 'rest-client'

module Models
  class TwitterProfile < ActiveRecord::Base
    include ::Models::Concerns::UsableTwitter
    validates :twitter_user_id, uniqueness: { scope: [:post_channel_id]  }

    def refresh_statistics(skip_save: false)
      data = fetch_data

      old_data = data.clone
      old_data[:screen_name] = self.screen_name
      old_data[:followers_count] = self.followers_count
      old_data[:friends_count] = self.friends_count
      old_data[:statuses_count] = self.statuses_count

      unless skip_save
        self.screen_name = data[:screen_name]
        self.followers_count = data[:followers_count]
        self.friends_count = data[:friends_count]
        self.statuses_count = data[:statuses_count]
        self.save!
      end

      [data, old_data]
    end

    def fetch_data
      data = twitter_client.user(twitter_user_id)
      {
        screen_name: data.screen_name.to_s,
        followers_count: data.followers_count.to_i,
        friends_count: data.friends_count.to_i,
        statuses_count: data.statuses_count.to_i,
      }
    rescue => e
      puts e.inspect
      nil
    end

    class << self
      def register(screen_name:, post_channel_id:)
        data = twitter_client.user(screen_name)
        TwitterProfile.create!(
          twitter_user_id: data.id,
          screen_name: data.screen_name.to_s,
          post_channel_id: post_channel_id,
        )
      end
    end
  end
end
