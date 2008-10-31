class AnnouncementPageController < WikiController
  
 
  def create
    @page_class = AnnouncementPage
    if params[:cancel]
      return redirect_to(create_page_url(nil, :group => params[:group]))
    elsif request.post?
      begin 
       @page = AnnouncementPage.create!(params[:page],:user => current_user,:share_with => params[:recipients],:access => (params[:access]||'view').to_sym,:flow => FLOW[:announcement])       
        return redirect_to(page_url(@page))
      rescue Exception => exc
        @page = exc.record
        flash_message_now :exception => exc
      end
    end
    @stylesheet = 'page_creation'
    render :template => 'announcement_page/create'
  end

  
  def show
    @wiki = @page
    render :controller => 'wiki', :action => 'show'
  end
  
  
private  
  
  # dump the sidebar
  def setup_default_view() end
  
  
  def create_new_page!(page_class)
     page_class.create!(params[:page].merge(
       :user => current_user,
       :share_with => params[:recipients],
       :access => (params[:access]||'view').to_sym
     ))  
  end
  
end
