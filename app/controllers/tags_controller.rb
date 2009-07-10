class TagsController < ApplicationController
  def show
    @tags = params[:id].split /\s*,\s*/
    @bookmarks = BookmarkSite.find_tagged_with(
      params[:id], :match_all => true, :order => 'updated_at DESC').paginate(
      :page => params[:page])

    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks)
    
    tag_cloud
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @date_groups }
    end
  end
end
