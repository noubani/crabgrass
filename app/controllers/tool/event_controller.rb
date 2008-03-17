require 'google_map'
require 'google_map_marker'

class Tool::EventController < Tool::BaseController
  helper :event_time 

  append_before_filter :fetch_event
  before_filter :login_required, :only => ['set_event_description', 'create', 'edit', 'update']
  
  def show
    @user_participation= UserParticipation.find(:first, :conditions => {:page_id => @page.id, :user_id => @current_user.id})  
    if @user_participation.nil?
      @user_participation = UserParticipation.new
      @user_participation.user_id = @current_user.id
      @user_participation.page_id = @page.id
      @user_participation.save
    end    
    @watchers = UserParticipation.find(:all, :conditions => {:page_id => @page.id, :watch => TRUE})  
    @attendies =  UserParticipation.find(:all, :conditions => {:page_id => @page.id, :attend => TRUE})  

  end

  def edit
  end
  
  def update
    # greenchange_note: currently, you aren't able to change a group
    # if one has already been set during event creation
    
    if request.post?
      @page.attributes = params[:page]
      @event.attributes = params[:event]

      # greenchange_note: HACK: all day events will be put in as UTC
      # noon (note: there is no 'UTC' timezone available, so we are
      # going to use 'London' for zero GMT offset as a hack for now)
      # so that when viewed in calendars or lists, the events will
      # always show up on the appropriate day ie, St. Patrick's day
      # should always be on the 17th of March regardless of my frame
      # of reference.  Also, since we have a programmatic flag to
      # identify all day events, this hack can be removed / migrated
      # later to any required handling of all day events that might be
      # more complex on the fetching side.
      if params[:event][:is_all_day] == '1'
        @event.time_zone = 'London' # greenchange_note: HACK: see above comment
        params[:time_start] =  params[:date_start] + " 12:00"
        params[:time_end] =  params[:date_start] + " 12:00"
      else
        params[:time_start] =  params[:date_start] + " "+ params[:hour_start]
        params[:time_end] =  params[:date_end] + " " + params[:hour_end]
      end

      @page.starts_at = TzTime.new(params[:time_start].to_time,TimeZone[@event.time_zone]).utc
      @page.ends_at = TzTime.new(params[:time_end].to_time,TimeZone[@event.time_zone]).utc

      if @event.state == 'Other'
        @event.state = params[:state_other]
      end

      if @page.save and @event.save
        return redirect_to(page_url(@page))
      else
        message :object => @page
      end
    end
  end

  def create
    @page_class = Tool::Event
    @event = ::Event.new(:time_zone => current_user.time_zone)   
    if request.post?
      @page = create_new_page @page_class
      @event = ::Event.new params[:event]

      # greenchange_note: HACK: all day events will be put in as UTC
      # noon (note: there is no 'UTC' timezone available, so we are
      # going to use 'London' for zero GMT offset as a hack for now)
      # so that when viewed in calendars or lists, the events will
      # always show up on the appropriate day ie, St. Patrick's day
      # should always be on the 17th of March regardless of my frame
      # of reference.  Also, since we have a programmatic flag to
      # identify all day events, this hack can be removed / migrated
      # later to any required handling of all day events that might be
      # more complex on the fetching side.
      if params[:event][:is_all_day] == '1'
        @event.time_zone = 'London' # greenchange_note: HACK: see above comment
        params[:time_start] =  params[:date_start] + " 12:00"
        params[:time_end] =  params[:date_start] + " 12:00"
      else
        params[:time_start] =  params[:date_start] + " "+ params[:hour_start]
        params[:time_end] =  params[:date_end] + " " + params[:hour_end]
      end

      @page.starts_at = TzTime.new(params[:time_start].to_time,TimeZone[@event.time_zone]).utc
      @page.ends_at = TzTime.new(params[:time_end].to_time,TimeZone[@event.time_zone]).utc

      if @event.state == 'Other'
        @event.state = params[:state_other]
      end

      # greenchange_note: all events are public right now per green change / seth
      @page.public = true

      @page.data = @event
      if @page.save
        return redirect_to(page_url(@page))
      else
        message :object => @page
      end
    end
  end
 
  def set_event_description
    @event.description =  params[:value]
    @event.save
    render :text => @event.description_html
  end

  def participate
    @user_participation = UserParticipation.find(:first, :conditions => {:page_id => @page.id, :user_id => @current_user.id})
    if !params[:user_participation_watch].nil? 
      @user_participation.watch = params[:user_participation_watch]
      @user_participation.attend = false
    else
      if !params[:user_participation_attend].nil?
        @user_participation.watch = false
        @user_participation.attend = params[:user_participation_attend]
      else
        @user_participation.watch = false
        @user_participation.attend = false
        # remove the user participation from the table?
      end
    end

    @user_participation.save
    
    @watchers = UserParticipation.find(:all, :conditions => {:page_id => @page.id, :watch => TRUE})
    @attendies =  UserParticipation.find(:all, :conditions => {:page_id => @page.id, :attend => TRUE})
    
  end
  
  protected

  def fetch_event
    return true unless @page
    @page.data ||= Event.new(:body => 'new page', :page => @page)
    @event = @page.data
  end
  
  def setup_view
    @show_attach = true
  end
  
  # set the right time format for the event
  def set_time (time)
    time
  end

  def authorized?
    if params[:action] == 'set_event_description' or params[:action] == 'edit' or params[:action] == 'update'
      return current_user.may?(:admin, @page)
    else
      return true
    end
  end
end
