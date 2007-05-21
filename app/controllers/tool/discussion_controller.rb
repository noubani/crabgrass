class Tool::DiscussionController < Tool::BaseController

  def show
    @comment_header = ""
  end
  
  protected
  
  def setup_view
    super
    # always show reply box
    @show_reply = true
    @show_workarea = false if params[:action] == 'show'
    true
  end
  
end
