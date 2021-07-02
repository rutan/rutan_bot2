require 'twitter'

module Models
  class SearchWords < ActiveRecord::Base
    include ::Models::Concerns::UsableTwitter
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
  end
end
