class PollVote < ActiveRecord::Base

  set_table_name 'votes'

  belongs_to :possible
  belongs_to :user
  has_many :polls, :finder_sql => 
    'SELECT polls.* FROM polls ' +
    'JOIN possibles ON possibles.poll_id = polls.id ' +
    'WHERE possibles.id = #{possible_id}'
  def poll
    polls.first
  end
  
end
