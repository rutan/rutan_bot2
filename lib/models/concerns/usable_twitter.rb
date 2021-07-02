require 'twitter'

module Models
  module Concerns
    module UsableTwitter
      extend ActiveSupport::Concern

      def twitter_client
        self.class.twitter_client
      end

      class_methods do
        def usable_twitter?
          ENV['TWITTER_CONSUMER_KEY'].to_s.size > 0
        end

        def twitter_client
          return nil unless usable_twitter?

          @twitter_client ||= Twitter::REST::Client.new do |config|
            config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
            config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
            config.access_token = ENV['TWITTER_ACCESS_TOKEN']
            config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
          end
        end
      end
    end
  end
end