require 'cgi'
require 'json'
require 'rest-client'

module Models
  class YoutubeChannel < ActiveRecord::Base
    validates :youtube_channel_id, uniqueness: { scope: [:post_channel_id]  }

    def refresh_statistics(skip_save: false)
      data = fetch_data

      old_data = data.clone
      old_data[:view_count] = self.view_count
      old_data[:subscriber_count] = self.subscriber_count

      unless skip_save
        self.title = data[:title]
        self.view_count = data[:view_count]
        self.subscriber_count = data[:subscriber_count]
        self.save!
      end

      [data, old_data]
    end

    def fetch_data
      url = "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings,statistics&id=#{CGI.escape youtube_channel_id}&key=#{YoutubeChannel.api_key}"
      resp = JSON.parse(RestClient.get(url))
      item = resp['items'].first
      {
        title: item['brandingSettings']['channel']['title'],
        view_count: item['statistics']['viewCount'].to_i,
        subscriber_count: item['statistics']['subscriberCount'].to_i,
      }
    rescue => e
      puts e.inspect
      nil
    end

    class << self
      def api_key
        ENV['YOUTUBE_API_KEY']
      end
    end
  end
end
