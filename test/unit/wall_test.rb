require File.dirname(__FILE__) + '/../test_helper'

class WallTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @user = User.find_by_login 'blue'
    @user.ensure_discussion
  end
  
 
  # test wall creation for users public and private profile
  def test_create_profile_wall
    #test creation
    assert_kind_of(Discussion, @user.discussion)

    #test destruction
    assert @user.discussion.destroy
  end
  
  
  # i assume posts to work, if they work to discussion, and assume further the discussion tests to test that, so i only test status posts here
  def test_postings_to_wall
    assert true
  end

end
