require File.dirname(__FILE__) + '/../test_helper'

class ConversationsControllerTest < ActionController::TestCase
  fixtures :users, :relationships

  def test_should_get_index
    get :index
    assert_login_required

    login_as :blue
    get :index
    assert_response :success
  end

  def test_should_show_conversation
    login_as :blue

    discussion = nil
    assert_difference 'Discussion.count' do
      get :show, :id => users(:orange).to_param
      discussion = assigns(:discussion)
    end

    assert_no_difference 'Discussion.count' do
      get :show, :id => users(:orange).to_param
      assert_equal discussion, assigns(:discussion)
    end

    assert_response :success

    login_as :orange

    assert_no_difference 'Discussion.count' do
      get :show, :id => users(:blue).to_param
      assert_equal discussion, assigns(:discussion)
    end

    assert_response :success
  end

  def test_should_update_conversation
    login_as :blue

    assert_difference 'Post.count' do
      assert_difference 'PrivatePostActivity.count' do
        put :update, :id => users(:orange).to_param, :post => {:body => 'hi'}
      end
    end

    assert_response :redirect

    get :index
    assert_response :success
  end

  def test_unread
    login_as :blue
    put :update, :id => users(:orange).to_param, :post => {:body => 'hi'}

    assert_equal 1, UnreadActivity.for_dashboard(users(:orange)).first.unread_count

    login_as :green
    put :update, :id => users(:orange).to_param, :post => {:body => 'hi'}

    assert_equal 2, UnreadActivity.for_dashboard(users(:orange)).first.unread_count

    login_as :orange
    get :show, :id => users(:blue).to_param
    assert_response :success

    assert_equal 1, UnreadActivity.for_dashboard(users(:orange)).first.unread_count
  end

#  def test_should_destroy_conversation
#    assert_difference('Conversation.count', -1) do
#      delete :destroy, :id => conversations(:one).id
#    end
#    assert_redirected_to conversations_path
#  end
end
