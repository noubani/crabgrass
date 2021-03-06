class StatsController < ApplicationController
  def index
    if defined?(ANALYZABLE_PRODUCTION_LOG) && File.file?(ANALYZABLE_PRODUCTION_LOG)
      render :text => '<pre>' + `pl_analyze #{ANALYZABLE_PRODUCTION_LOG}` + '</pre>'
    else
      render :text => 'no analyzable production log'
    end
  end
  
  
  def usage
    current_stats
    days_ago = (params[:id]||1).to_i
    stats_since( days_ago.days.ago )
    @header = "Usage in the past %s days" % days_ago
  end
  
  protected
  
  def stats_since(time)
    @pages_created = Page.count 'id', :conditions => ['created_at > ? AND flow IS NULL', time]
    @page_creators = Page.count_by_sql ["SELECT count(DISTINCT created_by_id) FROM pages WHERE created_at > ? AND FLOW IS NULL", time]
    @pages_updated = Page.count 'id', :conditions => ['updated_at > ? AND flow IS NULL', time]
    @page_updaters = Page.count_by_sql ["SELECT count(DISTINCT updated_by_id) FROM pages WHERE updated_at > ? AND FLOW IS NULL", time]
    @wikis_updated = Wiki.count 'id', :conditions => ['updated_at > ?', time]

    @users_created = User.on(current_site).count 'id', :conditions => ['created_at > ?', time]
    @total_users   = User.on(current_site).count
    @users_logged_in = User.on(current_site).count 'id', :conditions => ['last_seen_at > ?', time]
    
    @total_groups = Group.count
    @groups_created = Group.count 'id', :conditions => ['created_at > ?', time]
    counts_per_group = Membership.connection.select_values('SELECT count(id) FROM memberships GROUP BY group_id')
    buckets = {}
    counts_per_group.each{|i| i=i.to_i; buckets[i] ? buckets[i] += 1 : buckets[i] = 1 }
    puts buckets.inspect
    @membership_counts = buckets.sort{|a,b| b <=> a}
  end
  
  def current_stats
    @cur_users_logged_in = User.on(current_site).count 'id', :conditions => ['last_seen_at > ?', 15.minutes.ago]
    @cur_wiki_locks = Wiki.count 'id', :conditions => ["locked_at > ?", 60.minutes.ago]
  end
end
