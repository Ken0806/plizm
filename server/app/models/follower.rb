class Follower < ApplicationRecord
  belongs_to :following, class_name: 'User', :foreign_key => 'follow_to'
  belongs_to :follower, class_name: 'User', :foreign_key => 'followed_by'

  validates :follow_to,   presence: true
  validates :followed_by, presence: true
end
