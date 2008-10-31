class RenameContactsToUserRelations < ActiveRecord::Migration
  def self.up
    drop_table :user_relations rescue # drop if it happens to exist

    rename_table :contacts, :user_relations
    execute 'ALTER TABLE user_relations ADD COLUMN id int(11) NOT NULL auto_increment, ADD PRIMARY KEY (id)' rescue # add primary key if it doesn't exist.

    add_column :user_relations, :type, :string
    add_column :user_relations, :discussion_id, :integer
    rename_column :user_relations, :contact_id, :partner_id
  end

  def self.down
    rename_table :user_relations, :contacts
    execute 'ALTER TABLE contacts DROP PRIMARY KEY' rescue
    
    remove_column :contacts, :type
    remove_column :contacts, :discussion_id
    rename_column :contacts, :partner_id, :contact_id

  end
end
