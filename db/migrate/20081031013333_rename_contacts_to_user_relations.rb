class RenameContactsToUserRelations < ActiveRecord::Migration
  def self.up
    remove_index :contacts, :name => :index_contacts
    rename_table :contacts, :user_relations

    execute 'ALTER TABLE user_relations ADD COLUMN id int(11) NOT NULL auto_increment, ADD PRIMARY KEY (id)'

    add_column :user_relations, :type, :string
    add_column :user_relations, :discussion_id, :integer
    rename_column :user_relations, :contact_id, :partner_id

    add_index :user_relations, ['user_id', 'partner_id'], :name => 'index_ur'
  end

  def self.down
    remove_index :user_relations, :name => 'index_ur'
    remove_column :user_relations, :id
    rename_table :user_relations, :contacts

    remove_column :contacts, :type
    remove_column :contacts, :discussion_id
    rename_column :contacts, :partner_id, :contact_id

    add_index "contacts", ["contact_id", "user_id"], :name => "index_contacts"
  end
end

