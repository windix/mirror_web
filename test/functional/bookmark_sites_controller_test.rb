require 'test_helper'

class BookmarkSitesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bookmark_sites)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bookmark_site" do
    assert_difference('BookmarkSite.count') do
      post :create, :bookmark_site => { }
    end

    assert_redirected_to bookmark_site_path(assigns(:bookmark_site))
  end

  test "should show bookmark_site" do
    get :show, :id => bookmark_sites(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => bookmark_sites(:one).to_param
    assert_response :success
  end

  test "should update bookmark_site" do
    put :update, :id => bookmark_sites(:one).to_param, :bookmark_site => { }
    assert_redirected_to bookmark_site_path(assigns(:bookmark_site))
  end

  test "should destroy bookmark_site" do
    assert_difference('BookmarkSite.count', -1) do
      delete :destroy, :id => bookmark_sites(:one).to_param
    end

    assert_redirected_to bookmark_sites_path
  end
end
