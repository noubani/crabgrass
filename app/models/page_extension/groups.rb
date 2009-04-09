=begin

RELATIONSHIP TO GROUPS
    
=end

module PageExtension::Groups

  def self.included(base)
    base.extend(ClassMethods)
    base.instance_eval do

      has_many :group_participations, :dependent => :destroy
      has_many :groups, :through => :group_participations

      # the primary group will be equal to the owner if the owner is a group.
      belongs_to :group                       # the primary group
      belongs_to :owner, :polymorphic => true # the page owner

      has_many :namespace_groups, :class_name => 'Group', :finder_sql => 'SELECT groups.* FROM groups WHERE groups.id IN (#{namespace_group_ids_sql})'

      # override the ActiveRecord created method
      remove_method :namespace_group_ids
      remove_method :group_ids
    end
  end

  # When getting a list of ids of groups for this page,
  # we use group_participations. This way, we will have
  # current data even if a group is added and the page
  # has not yet been saved.
  def group_ids
    group_participations.collect{|gpart|gpart.group_id}
  end
  
  # returns an array of group ids that compose this page's namespace
  # includes direct groups and all the relatives of the direct groups.
  def namespace_group_ids
    Group.namespace_ids(group_ids)
  end
  def namespace_group_ids_sql
    namespace_group_ids.any? ? namespace_group_ids.join(',') : 'NULL'
  end

  # takes an array of group ids, return all the matching group participations
  # this is called a lot, since it is used to determine permission for the page
  def participation_for_groups(group_ids) 
    group_participations.collect do |gpart|
      gpart if group_ids.include? gpart.group_id
    end.compact
  end
  def participation_for_group(group)
    group_participations.detect{|gpart| gpart.group_id == group.id}
  end

  # a list of the group participation objects, but sorted
  # by access (higher number is less access permissions)
  def sorted_group_participations
    group_participations.sort do |a,b|
      (a.access||100) <=> (b.access||100)
    end
  end

  # returns all the groups with a particular access level
  # - use option :all for all the accesslevels
  # --
  #   TODO
  #   what is the purpose of this method? 
  #
  #   i think it can be removed.
  #
  #   also, page.groups_with_access(:all) will always be equal to page.groups
  #   groups don't have a group_participation record unless they have been
  #   granted access (unlike user_participation records)
  #
  #   -elijah
  # --
  def groups_with_access(access)
    group_participations.collect do |gpart|
      if access == :all
        gpart.group if ACCESS.include?(gpart.access)
      else  
        gpart.group if gpart.access == ACCESS[access]
      end  
    end.compact
  end

  module ClassMethods
    #
    # returns an array of the number of pages in each month for a particular group.
    # (based on what pages the current_user can see)
    # 
    def month_counts(options)
      group = options[:group]
      current_user = options[:current_user]
      field = case options[:field]
        when 'created': 'created_at'
        when 'updated': 'updated_at'
        when 'starts': 'starts_at'
        else 'error'
      end

      if current_user and current_user.may?(:edit, group)
        # current_user can see all the group's pages
        access_filter = PageTerms.access_filter_for(group)
      elsif current_user
        # current_user can see public pages OR pages it has access to.
        access_filter = "(%s) (%s)" % [PageTerms.access_filter_for(group, :public), PageTerms.access_filter_for(group, current_user)]
      else
        # only show public pages
        access_filter = PageTerms.access_filter_for(group, :public)
      end

      sql = "SELECT MONTH(pages.#{field}) AS month, YEAR(pages.#{field}) AS year, count(pages.id) as page_count "
      sql += "FROM pages JOIN page_terms ON pages.id = page_terms.page_id "
      sql += "WHERE MATCH(page_terms.access_ids,page_terms.tags) AGAINST ('%s' IN BOOLEAN MODE) AND pages.flow IS NULL " % access_filter
      sql += "GROUP BY year, month ORDER BY year, month"
      Page.connection.select_all(sql)
    end
  end

end
