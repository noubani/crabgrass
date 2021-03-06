#
#
# Everything to do with user <> user relationships should be here.
#
# "relationships" is the join table:
#    user has many users through relationships
# 
module UserExtension::Users

  def self.included(base)

    base.send :include, InstanceMethods

    base.instance_eval do
  
      serialize_as IntArray, :friend_id_cache, :foe_id_cache

      initialized_by :update_contacts_cache,
        :friend_id_cache, :foe_id_cache

      ## PEERS
      
      # (peer_id_cache defined in UserExtension::Organize)
      has_many :peers, :class_name => 'User',
        :finder_sql => 'SELECT users.* FROM users WHERE users.id IN (#{peer_id_cache.to_sql})' do
        # will_paginate bug: Association with finder_sql raises TypeError
        #  http://sod.lighthouseapp.com/projects/17958/tickets/120-paginate-association-with-finder_sql-raises-typeerror#ticket-120-5
        def find(*args)
          options = args.extract_options!
          sql = @finder_sql
  
          sql += " ORDER BY " + sanitize_sql(options[:order]) if options[:order]
          sql += sanitize_sql [" LIMIT ?", options[:limit]] if options[:limit]
          sql += sanitize_sql [" OFFSET ?", options[:offset]] if options[:offset]

          User.find_by_sql(sql)
        end
      end

      # same as results as user.peers, but chainable with other named scopes
      named_scope(:peers_of, lambda do |user|
        {:conditions => ['users.id in (?)', user.peer_id_cache]}
      end)

      ## USER'S STATUS / PUBLIC WALL

      has_one :discussion, :as => :commentable, :dependent => :destroy
      alias_method_chain :discussion, :auto_create

      ## RELATIONSHIPS

      has_many :relationships, :dependent => :destroy do
        def with(user) find_by_contact_id(user.id) end
      end
      has_many :discussions, :through => :relationships
      has_many :contacts,    :through => :relationships
      has_many :friends,     :through => :relationships,
        :conditions => "relationships.type = 'Friendship'", :source => :contact

      # same result as user.friends, but chainable with other named scopes
      named_scope(:friends_of, lambda do |user|
        {:conditions => ['users.id in (?)', user.friend_id_cache]}
      end)

#      has_and_belongs_to_many :contacts,
#        {:class_name => "User",
#        :join_table => "contacts",
#        :association_foreign_key => "contact_id",
#        :foreign_key => "user_id",
#        :uniq => true} do
#          def online
#            find( :all, 
#              :conditions => ['users.last_seen_at > ?',10.minutes.ago],
#              :order => 'users.last_seen_at DESC' )
#          end
#          def logins_only
#            find( :all, :select => 'users.login')
#          end
#      end

    end 
  end
  
  module InstanceMethods

    ##
    ## STATUS / PUBLIC WALL
    ##
    
    # returns the users current status by returning his latest status_posts.body
    def current_status
      self.discussion.posts.find_all_by_type('StatusPost').last.body rescue nil
    end

    def discussion_with_auto_create(*args)
      discussion_without_auto_create(*args) or begin
        self.discussion = Discussion.create do |d|
          d.commentable = self
        end
      end  
    end

    ##
    ## RELATIONSHIPS
    ##

    # Creates a relationship between self and other_user. This should be the ONLY
    # way that contacts are created.
    # 
    # If type is :friend or "Friendship", then the relationship from self to other
    # user will be one of friendship.
    #
    # This method can be used to either add a new relationship or to update an
    # an existing one
    #
    # RelationshipObserver creates a new FriendActivity when a friendship is created.
    # As a side effect, this will create a profile for 'self' if it does not
    # already exist.
    #
    def add_contact!(other_user, type=nil)
      type = 'Friendship' if type == :friend

      unless relationship = other_user.relationships.with(self)
        relationship = Relationship.new(:user => other_user, :contact => self)
      end
      relationship.type = type
      relationship.save!

      unless relationship = self.relationships.with(other_user)
        relationship = Relationship.new(:user => self, :contact => other_user)
      end
      relationship.type = type
      relationship.save!

      self.relationships.reset
      self.contacts.reset
      self.friends.reset
      self.update_contacts_cache

      other_user.relationships.reset
      other_user.contacts.reset
      other_user.friends.reset
      other_user.update_contacts_cache

      return relationship
    end

    # this should be the ONLY way contacts are deleted
    def remove_contact!(other_user)
      if self.relationships.with(other_user)
        self.contacts.delete(other_user)
        self.update_contacts_cache
      end
      if other_user.relationships.with(self)
         other_user.contacts.delete(self)
         other_user.update_contacts_cache
      end
    end
    
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
      (@tmp_relationships_hash ||= {})[user.login] ||= get_relationships_to(user)
    end
    def get_relationships_to(user)
      ret = []
      ret << :friend   if friend_of?(user)
      ret << :peer     if peer_of?(user)
  #   ret << :fof      if fof_of?(user)
      ret << :stranger if ret.empty?
      ret
    end

    ##
    ## PERMISSIONS
    ##

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

  end # InstanceMethods

end
