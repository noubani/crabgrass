=begin

Everything to do with user <> user relationships should be here.

=end

module UserExtension::Socialize
  def self.included(base)
    base.instance_eval do
  
      serialize_as IntArray, :friend_id_cache, :foe_id_cache

      initialized_by :update_contacts_cache,
        :friend_id_cache, :foe_id_cache
      
      # (peer_id_cache defined in UserExtension::Organize)
      has_many :peers, :class_name => 'User',
        :finder_sql => 'SELECT users.* FROM users WHERE users.id IN (#{peer_id_cache.to_sql})'

      # discussion
      has_one :discussion, :as => :commentable
      has_many :discussions, :through => :user_relations
      
      #########
      # User to User Relations
      # Association is in  app/models/associations/user_relation.rb
      #########
      
      has_many :user_relations, :dependent => :destroy
      has_many :partner_relations, :foreign_key => "partner_id", :class_name => "UserRelation", :uniq => true, :dependent => :destroy

      
      has_many :partners, :through => :partner_relations, :source => :user, :foreign_key => "partner_id", :uniq => true do
        def online
          find( :all, 
            :conditions => ['users.last_seen_at > ?',10.minutes.ago],
            :order => 'users.last_seen_at DESC' )
        end
      end
  
      alias_method :contacts, :partners
      
      
      has_many :friendships, :dependent => :destroy
  # in this case: works    
      has_many :friendrelations, :class_name => "Friendship", :foreign_key => :partner_id, :uniq => true
      has_many :friends, :through => :friendrelations, :source => :user, :foreign_key => "partner_id", :uniq => true do
  # in this case:
  # a.friends << b
  # puts b.friends
  # => [b]
  #    has_many :friends, :through => :friendships, :source => :user, :foreign_key => "partner_id", :class_name => "User", :uniq => true do
 
      
        def online
          find( :all, 
            :conditions => ['users.last_seen_at > ?',10.minutes.ago],
            :order => 'users.last_seen_at DESC' )
        end
      end  
      
      # TODO
      # This should be rewritten as a extension for usage like that:
      # define_user_relations :user_relation, :friendship
      #
      # maybe the STI in the association should be metagenerated, too
      
      # changes the type of the user_relationc
      def change_user_relation other, type
        rel1 = UserRelation.find_by_user_id_and_partner_id(self.id, other.id)
        rel1.type = type
        rel1.save
        rel2 = UserRelation.find_by_user_id_and_partner_id(other.id,self.id)
        rel2.type = type
        rel2.save
      end
   
    end
  end

  ## CONTACTS

  # this should be the ONLY way that contacts are created
  def add_contact!(other_user, set_type=nil)
    # we only have friends and normal relations at the moment
    if set_type == :friend
      set_type == "Friendship"
    else
      set_type == nil
    end
    
    # check in the one direction
    
    rel1 = self.user_relations.find_by_partner_id(other_user.id)
    rel2 = other_user.user_relations.find_by_partner_id(self.id)
    if rel1
      rel1.update_attribute(:type,set_type) unless rel1.type == set_type
    else
      rel1 = UserRelation.create!(:user_id => self.id, :partner_id => other_user.id, :type => set_type)
    end
    if rel2
    rel2.update_attribute(:type,set_type) unless rel2.type == set_type
    else
    rel2 = UserRelation.create!(:user_id => other_user.id, :partner_id => self.id, :type => set_type)
    end
    self.contacts.reset
    self.update_contacts_cache
    other_user.contacts.reset
    other_user.update_contacts_cache
=begin    
    unless self.contacts.include?(other_user)
      UserRelation.create!(:user_id => self.id, :partner_id => other_user.id, :type => type)
      self.contacts.reset
      self.update_contacts_cache
    end
    # check the other direction
    unless other_user.contacts.include?(self)
     UserRelation.create!(:user_id => other_user.id, :partner_id => self.id, :type => type)
      other_user.contacts.reset
      other_user.update_contacts_cache
    end
=end
  end

  # this should be the ONLY way contacts are deleted
  def remove_contact!(other_user, type=nil)
    
    
    
    if rel1 = self.user_relations.find_by_partner_id_and_type(other_user.id,type)
      rel1.destroy
      self.update_contacts_cache
    end  
    if rel2 = other_user.user_relations.find_by_partner_id_and_type(self.id,type)
       rel2.destroy
       other_user.update_contacts_cache
    end
  end
  
  ## PERMISSIONS

  def may_be_pestered_by?(user)
    begin
      may_be_pestered_by!(user)
    rescue PermissionDenied
      false
    end
  end
  
  def may_be_pestered_by!(user)
    # TODO: perhaps being someones friend or peer does not automatically
    # mean that you can pester them. It should all be based on the profile?
    if friend_of?(user) or peer_of?(user) or profiles.visible_by(user).may_pester?
      return true
    else
      raise PermissionDenied.new('You not allowed to share with %s'[:pester_denied] % self.name)
    end
  end

  def may_pester?(entity)
    entity.may_be_pestered_by? self
  end
  def may_pester!(entity)
    entity.may_be_pestered_by! self
  end

  ## Discussions
  
  def ensure_discussion
    unless self.discussion
      self.discussion = Discussion.create()
      self.discussion.user = self
    end
    self.discussion
  end
  
  ## RELATIONSHIPS

  def stranger_to?(user)
    !peer_of?(user) and !contact_of?(user)
  end
  
  def peer_of?(user)
    id = user.instance_of?(Integer) ? user : user.id
    peer_id_cache.include?(id)  
  end
  
  def friend_of?(user)
    id = user.instance_of?(Integer) ? user : user.id
    friend_id_cache.include?(id)
  end
  alias :contact_of? :friend_of?
  
  def relationship_to(user)
    relationships_to(user).first
  end
  def relationships_to(user)
    return :stranger unless user
    (@relationships ||= {})[user.login] ||= get_relationships_to(user)
  end
  def get_relationships_to(user)
    ret = []
    ret << :friend   if friend_of?(user)
    ret << :peer     if peer_of?(user)
#   ret << :fof      if fof_of?(user)
    ret << :stranger if ret.empty?
    ret
  end
end
