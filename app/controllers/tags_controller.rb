class TagsController < ApplicationController
  def show
    @current_tags = params[:id].split /\s*,\s*/
    
    if logged_in? 
      @bookmarks = BookmarkSite.find_tagged_with(
        params[:id], :match_all => true, :conditions => ['user_id = ?', current_user.id], 
        :order => 'updated_at DESC').paginate(:page => params[:page])
    else
      @bookmarks = BookmarkSite.find_tagged_with(
        params[:id], :match_all => true, :conditions => ['do_not_share = ?', 0], 
        :order => 'updated_at DESC').paginate(:page => params[:page])
    end

    logger.info "RELATED TAGS START"    
    @related_tags = BookmarkSite.find_related_tags(@current_tags, {}, @bookmarks)
    logger.info "RELATED TAGS END"    

    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks)
    
    tag_cloud
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @date_groups }
    end
  end
end
