require File.dirname(__FILE__) + '/../../test_helper'
require 'tool/info_controller'

# Re-raise errors caught by the controller.
class Tool::InfoController; def rescue_action(e) raise e end; end

class Tool::InfoControllerTest < Test::Unit::TestCase
  fixtures :pages, :users, :user_participations

  def setup
    @controller = Tool::InfoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show
    #TODO: figure out what this controller does and write a test for it
  end

end