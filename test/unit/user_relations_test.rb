require File.dirname(__FILE__) + '/../test_helper'

class UserRelationsTest < Test::Unit::TestCase
  fixtures :users

  def test_contacts
    a = users(:red)
    b = users(:green)
    
    assert !a.contacts.include?(b), 'no contact yet'
    a.add_contact!(b)
    assert a.contacts.include?(b), 'should be contact'
    a.reload
    # has been user_id_cache before, which won't work NOTE THIS, PLEASE!
    assert a.friend_id_cache.include?(b.id), 'friend id cache should be updated'
    assert a.friend_of?(b), 'should be friends'
    assert b.friend_of?(a), 'should be friends both ways'
    a.remove_contact!(b)
    assert !a.contacts.include?(b), 'no contact now'
  end
=begin
  def test_friendships
    c = users(:green)
    d = users(:yellow)
    assert !c.friends.include?(d), 'no friend yet'
    c.add_contact!(d, :friend)
    assert c.friends.include?(d), 'should be friend'
  end
=end  
  def test_duplicate_contacts
    a = users(:red)
    b = users(:green)
    
    a.add_contact!(b)
    a.add_contact!(b)
    
    assert_equal 1, UserRelation.count(:conditions => ['user_id = ? and partner_id = ?', a.id, b.id]), 'should be only be one contact, but there are really two (or less, check the count!)'
  end
=begin
  def test_duplicate_friendships
    
  end
=end  
  def test_associations
    assert check_associations(Contact)
  end  

end

