class PrivatePostActivity < Activity

  validates_format_of :subject_type, :with => /User/
  validates_presence_of :subject_id

  validates_format_of :object_type, :with => /User/
  validates_presence_of :object_id

  alias_attr :user_to, :subject
  alias_attr :user_from, :object
  alias_attr :post_id, :related_id
  alias_attr :snippet, :extra
  alias_attr :reply, :flag

  def post=(post)
    self.post_id = post.id
    self.snippet = GreenCloth.new(post.body[0..140], 'page', [:lite_mode]).to_html
    self.snippet += '...' if post.body.length > 140
  end

  protected

  before_create :set_access
  def set_access
    self.access = Activity::PRIVATE
  end

  public

  def description(view)
    url = view.send(:conversation_path, :id => user_from_name)
    link_text = reply ? 'a reply'[:a_reply_link] : 'a message'[:a_message_link]

    "You received {message_tag} from {other_user}: {title}"[
       :activity_message_received,
       {
         :message_tag => view.link_to(link_text, url),
         :other_user => user_span(:user_from),
         :title => "<i>#{snippet}</i>"
       }
    ]
  end

  def icon
    'page_message'
  end

end

