require File.dirname(__FILE__) + '/../test_helper'
require 'assets_controller'

# Re-raise errors caught by the controller.
class AssetsController; def rescue_action(e) raise e end; end

class AssetsControllerTest < Test::Unit::TestCase
  fixtures :users, :pages, :user_participations
  @@private = Media::AssetStorage.private_storage = "#{RAILS_ROOT}/tmp/private_assets"
  @@public = Media::AssetStorage.public_storage = "#{RAILS_ROOT}/tmp/public_assets"

  def setup
    @controller = AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    FileUtils.mkdir_p(@@private)
    FileUtils.mkdir_p(@@public)
    Media::Process::Base.log_to_stdout_when = :on_error
  end

  def teardown
    FileUtils.rm_rf(@@private)
    FileUtils.rm_rf(@@public)
  end

  def test_show
    @asset = Asset.create :uploaded_data => upload_data('photo.jpg')
    @page = create_page :data => @asset
    @asset.uploaded_data = upload_data('image.png')
    @asset.save

    @controller.stubs(:public_or_login_required).returns(true)
    @controller.stubs(:is_public).returns(false)

    post :show, :id => @asset.id, :filename => [@asset.filename]
    assert_response :success, "should get asset"
    assert_equal @asset.private_filename, assigns(:asset).private_filename, "should be expected asset"

    post :show, :id => @asset.id, :filename => [@asset.filename], :version => 1
    assert_response :success, "should get version 1 of asset"
    assert_equal @asset.versions.earliest.private_filename, assigns(:asset).private_filename, "should be version 1 of asset"

    post :show, :id => @asset.id, :filename => [@asset.filename], :version => 2
    assert_response :success, "should get version 1 of asset"
    assert_equal @asset.versions.latest.private_filename, assigns(:asset).private_filename, "should be version 2 of asset"
    
    post :show, :id => @asset.id, :filename => [@asset.filename], :version => 3
    assert_response :not_found, "should not find anything for version 2 of asset"
  end
  
  def test_create
    login_as :blue
    
    assert_difference 'Page.find(1).assets.length' do
      post 'create', :asset => {:uploaded_data => upload_data('photo.jpg'), :page_id => 1}
    end

    assert_difference 'Page.find(1).assets.length' do
      post 'create', :asset => {:uploaded_data => upload_data('photo.jpg'), :page_id => 1}
    end
  end
  
  def test_destroy
    login_as :blue
    
    assert_difference 'Page.find(1).assets.length' do
      post 'create', :asset => {:uploaded_data => upload_data('photo.jpg'), :page_id => 1}
    end

    assert_difference 'Page.find(1).assets.length', -1 do
      post 'destroy', :id => assigns(:asset).id
    end
  end

  protected

  def create_page(options = {})
    defaults = {:title => 'untitled page', :public => false}
    AssetPage.create(defaults.merge(options))
  end
end