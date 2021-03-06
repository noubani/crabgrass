require "#{File.dirname(__FILE__)}/../../test_helper"

class Me::DashboardTest < ActionController::IntegrationTest
  def test_hide_show_welcome_message_persists
    login 'blue'
    visit '/me/dashboard'

    assert_contain "Hide Welcome"

    visit '/me/dashboard/close_welcome_box' # simulate an ajax method
    visit 'me/dashboard'

    assert_contain "Show Welcome"
    assert_have_no_selector "#welcome_box table"

    # show the welcome again
    visit '/me/dashboard/show_welcome_box' # simulate an ajax method
    visit 'me/dashboard'

    assert_contain "Hide Welcome"
    assert_not_contain "Show Welcome"
    assert_have_selector "#welcome_box table"
  end

  def test_set_status
    login 'orange'

    visit '/me/dashboard'
    # identify the field by id attribute
    fill_in 'say_text', :with => 'Staying orange here'
    click_button 'Update Status'

    assert_contain 'My Dashboard'
    # select the text input
    assert_have_selector "#say_text", :content => 'Staying orange here'
    # check text with regular expression
    assert_contain %r{Orange! Staying orange here}
  end

  def test_joining_network_updates_dashboard
    login 'aaron'
    visit '/cnt'
    click_link 'Request to Join Network'
    click_button 'Send Request'
    assert_contain 'Request to join has been sent'

    login 'blue'
    visit '/me/dashboard'
    click_link 'Requests'
    assert_contain 'Aaron! requested to join Confederación Nacional del Trabajo'

    click_link 'approve' # will click the first one
    assert_not_contain 'Aaron! requested to join Confederación Nacional del Trabajo'

    login 'aaron'
    visit '/me/dashboard'

    assert_contain %r{My World\s*Networks\s*Confederación Nacional del Trabajo \(cnt\)}
  end

  def test_joining_group_updates_dashboard
    login 'aaron'

    visit '/animals'

    # EXAMPLE: save_and_open
    # this command will open up a browser and show what webrat sees
    # useful for debugging
    ##
    ## save_and_open_page
    ##

    click_link 'Request to Join Group'
    click_button 'Send Request'

    assert_contain 'Request to join has been sent'


    login 'dolphin'
    visit '/me/dashboard'
    click_link 'Requests'
    assert_contain 'Aaron! requested to join animals'

    click_link 'approve' # will click the first one
    assert_not_contain 'Aaron! requested to join animals'

    login 'aaron'
    visit '/me/dashboard'
    assert_contain %r{Groups\s*animals}
  end
end
