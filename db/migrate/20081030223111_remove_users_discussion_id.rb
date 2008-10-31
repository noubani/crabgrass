class RemoveUsersDiscussionId < ActiveRecord::Migration
  def self.up
    remove_column :users, :discussion_id
  end

  def self.down
    add_column :users, :discussion_id, :integer
  end
end
