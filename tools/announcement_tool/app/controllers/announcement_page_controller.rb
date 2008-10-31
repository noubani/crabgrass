class AnnouncementPageController < WikiPageController
  
 
  def create
    @page_class = AnnouncementPage
    @stylesheet = 'page_creation'
    if params[:cancel]
      return redirect_to(create_page_url(nil, :group => params[:group]))
    elsif request.post?
      begin 
       @page = AnnouncementPage.create!(params[:page],:user => current_user,:share_with => params[:recipients],:access => (params[:access]||'view').to_sym,:flow => FLOW[:announcement])       
       if params[:asset][:uploaded_data].any?
          @asset = Asset.make!(params[:asset].merge(:parent_page => @page))
          image_tag = "!<%s!:%s" % [@asset.thumbnail(:medium).url,@asset.url]
        end
        body = "%s\n\n%s" % [image_tag, params[:body]]
        @wiki = Wiki.create!(:user => current_user, :body => body)
        @page.update_attribute(:data, @wiki)
        redirect_to(page_url(@page))
      rescue Exception => exc
        @wiki.destroy if @wiki
        @asset.destroy if @asset
        @page = exc.record if exc.record.is_a? Page
        flash_message_now :exception => exc
      end
   
    end
    render :template => 'announcement_page/create'
  end  
  
  def show
    if @wiki.body.empty?
  #    raise 'Announcement has no Content'
    elsif @upart and !@upart.viewed? and @wiki.version > 1
      @last_seen = @wiki.first_since( @upart.viewed_at )
    end
  end
  
  
private  
  
  # dump the sidebar
  def setup_default_view() end
  
  def fetch_wiki
    return true unless @page
    raise "Announcement has no Content" unless @wiki = @page.data
    @locked_for_me = !@wiki.editable_by?(current_user) if logged_in?
  end
  
end
