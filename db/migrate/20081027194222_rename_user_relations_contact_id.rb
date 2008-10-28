class RenameUserRelationsContactId < ActiveRecord::Migration
  def self.up
    rename_column :user_relations, :contact_id, :partner_id
  end

  def self.down
    rename_column :user_relations, :partner_id, :contact_id
  end
end
