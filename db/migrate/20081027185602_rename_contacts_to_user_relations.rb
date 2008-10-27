class RenameContactsToUserRelations < ActiveRecord::Migration
  def self.up
    drop_table :user_relations
    rename_table :contacts, :user_relations
    add_column :user_relations, :id, :integer
    add_column :user_relations, :type, :string
    add_column :user_relations, :discussion_id, :integer
    add_column :user_relations, :user_id, :integer
    add_column :user_relations, :partner_id, :integer
  
  
  end

  def self.down
    rename_table :user_relations, :contacts
    remove_column :user_relations, :id
    remove_column :user_relations, :type
    remove_column :user_relations, :discussion_id
    remove_column :user_relations, :user_id
    remove_column :user_relations, :partner_id
    create_table :user_relations do |t|
      t.integer :partner_id
      t.integer :user_id
      t.string :type
      t.integer :discussion_id
    end
  end
end
