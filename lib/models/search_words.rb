require 'twitter'

module Models
  class SearchWords < ActiveRecord::Base
    validates :channel_id, uniqueness: true

    def update_since_id!
      self.since_id = twitter_client.search(keyword,
        result_type: 'recent',
        count: 1,
      ).first&.id.to_i
      save!
    end

    def search!
      twitter_client.search("#{keyword} exclude:retweets",
        result_type: 'recent',
        count: 100,
      )
        .take(100)
        .sort { |a, b| a.id <=> b.id }
        .select { |t| t.id > since_id.to_i }
        .tap do |results|
          next if results.empty?
          update(since_id: results.last.id)
        end
    end

    private

    def twitter_client
      @twitter_client ||= Twitter::REST::Client.new do |config|
        config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token = ENV['TWITTER_ACCESS_TOKEN']
        config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
      end
    end

    class << self
      def usable_twitter?
        ENV['TWITTER_CONSUMER_KEY'].to_s.size > 0
      end
    end
  end
end
