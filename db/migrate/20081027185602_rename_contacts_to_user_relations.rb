class RenameContactsToUserRelations < ActiveRecord::Migration
  def self.up
    drop_table :user_relations
    rename_table :contacts, :user_relations
    execute 'ALTER TABLE user_relations ADD COLUMN id int(11) NOT NULL auto_increment, ADD PRIMARY KEY (id)'
    add_column :user_relations, :type, :string
    add_column :user_relations, :discussion_id, :integer
    add_column :user_relations, :user_id, :integer
    add_column :user_relations, :contact_id, :integer
  end

  def self.down
     rename_table :user_relations, :contacts
     execute 'ALTER TABLE contacts DROP PRIMARY KEY'
    remove_column :contacts, :type
    remove_column :contacts, :discussion_id
    remove_column :contacts, :user_id
    remove_column :contacts, :partner_id
    create_table :user_relations do |t|
      t.integer :partner_id
      t.integer :user_id
      t.string :type
      t.integer :discussion_id
    end
  end
end
