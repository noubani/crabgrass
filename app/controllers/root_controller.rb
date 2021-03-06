#
# This controller is in charge of rendering the root url.
#
class RootController < ApplicationController

  helper :groups, :account, :wiki
  stylesheet 'wiki_edit'
  javascript 'wiki_edit'
  permissions 'groups/base'
  before_filter :login_required, :except => ['index']
  before_filter :fetch_network

  def index
    if !logged_in?
      login_page
    elsif current_site.network
      site_home
    else
      redirect_to me_url
    end
  end

  ##
  ## TAB CONTENT, PULLED BY AJAX
  ##

  def featured
    update_page_list('featured_panel',
      :pages => paginate('featured_by', @group.id, 'descending', 'updated_at')
    )
  end

  def most_viewed
    update_page_list("most_viewed_panel",
      :pages => pages_for_timespan('most_views'),
      :columns => [:views, :icon, :title, :last_updated],
      :sortable => false,
      :heading_partial => 'root/time_links',
      :pagination_options => {:params => {:time_span => params[:time_span]}}
    )
  end

  def most_active
    update_page_list("most_active_panel",
      :pages => pages_for_timespan('most_edits'),
      :columns => [:contributors, :icon, :title, :last_updated],
      :sortable => false,
      :heading_partial => 'root/time_links',
      :pagination_options => {:params => {:time_span => params[:time_span]}}
    )
  end

  def most_stars
    update_page_list("most_stars_panel",
      :pages => pages_for_timespan('most_stars'),
      :columns => [:stars, :icon, :title, :last_updated],
      :sortable => false, 
      :heading_partial => 'root/time_links', 
      :pagination_options => {:params => {:time_span => params[:time_span]}}
    )
  end

  def announcements
    update_page_list('announcements_panel', 
      :pages => paginate('descending','created_at', :flow => :announcement)
    )
  end

  def recent_pages
    update_page_list('recent_pages_panel', 
      :pages => paginate('descending', 'updated_at'),
      :columns => [:stars, :icon, :title, :last_updated], 
      :sortable => false,
      :show_time_dividers => true
    )
  end

  protected

  def pages_for_timespan(filter_by)
    time_span = params[:time_span] || 'all_time'
    case time_span
    when 'today' then
      paginate(filter_by, '24', 'hours')
    when 'this_week' then
      paginate(filter_by, '7', 'days')
    when 'this_month' then
      paginate(filter_by, '30', 'days')
    when 'all_time' then
      case filter_by
      when 'most_views' then
        paginate('descending','views_count')
      when 'most_edits' then
        paginate('descending', 'contributors_count') #TODO: contributors count does not seem to get updated
      when 'most_stars' then
        paginate('descending','stars_count')
      end
    end
  end

  def authorized?
    true
  end

  def site_home
    @active_tab = :home
    @group.profiles.public.create_wiki unless @group.profiles.public.wiki
    @announcements = Page.find_by_path('limit/3/descending/created_at',
      options_for_group(@group, :flow => :announcement))
    render :template => 'root/site_home'    
  end

  def login_page
    @stylesheet = 'account'
    @active_tab = :home
    render :template => 'account/index'
  end

  def fetch_network
    @group = current_site.network if current_site and current_site.network
  end

  def paginate(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    Page.paginate_by_path(args, options_for_group(@group, {:page => params[:page]}.merge(options)))
  end

  def update_page_list(target, locals)   
    render :update do |page|
      page.replace_html target, :partial => 'pages/list', :locals => locals
    end
  end

#  def render_timed_panel
#      render :update do |page|
#        page.replace_html "#{@panel}_panel", :partial => 'root/timed_panel', :locals => {:panel => @panel}
#      end
#  end

  ##
  ## lists of active groups and users. used by the view. 
  ##

  helper_method :most_active_groups
  def most_active_groups
    Group.only_groups.most_visits.find(:all, :limit => 5)
  end
  
  helper_method :recently_active_groups
  def recently_active_groups
    Group.only_groups.recent_visits.find(:all, :limit => 10)
  end

  helper_method :most_active_users
  def most_active_users
    User.most_active_on(current_site, nil).not_inactive.find(:all, :limit => 5)
  end

  helper_method :recently_active_users
  def recently_active_users
    User.most_active_on(current_site, Time.now - 30.days).not_inactive.find(:all, :limit => 10)
  end

end

