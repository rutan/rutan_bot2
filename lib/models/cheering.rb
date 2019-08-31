module Models
  class Cheering < ActiveRecord::Base
    validates :emoji, uniqueness: true

    class << self
      def pick_random
        self.offset(rand(self.count)).limit(1).first
      end
    end
  end
end
