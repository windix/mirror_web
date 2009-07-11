class BookmarkSitesController < ApplicationController
  before_filter :login_required, :only => [ :new, :edit, :create, :update, :destroy ]

  # GET /bookmark_sites
  # GET /bookmark_sites.xml
  def index
    if logged_in?
      @bookmarks = BookmarkSite.all_for_user(current_user).paginate :page => params[:page]
    else
      @bookmarks = BookmarkSite.all.paginate :page => params[:page]
    end
    
    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks)

    tag_cloud

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @date_groups }
    end
  end

  # GET /bookmark_sites/1/version
  # GET /bookmark_sites/1/version.xml
  def versions
    @bookmark = BookmarkSite.find(params[:id])

    @bookmarks = @bookmark.versions(current_user).paginate :page => params[:page]
    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks, :last_modified)

    tag_cloud_for_versions(@bookmarks)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @date_groups }
    end
  end

  # GET /bookmark_sites/1
  # GET /bookmark_sites/1.xml
  def show
    @bookmark_site = BookmarkSite.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bookmark_site }
    end
  end

  # GET /bookmark_sites/new
  # GET /bookmark_sites/new.xml
  def new
    @bookmark_site = BookmarkSite.new(:url => params[:url],
      :title => params[:title])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bookmark_site }
    end
  end

  # GET /bookmark_sites/1/edit
  def edit
    @bookmark_site = BookmarkSite.find(params[:id])
  end

  # POST /bookmark_sites
  # POST /bookmark_sites.xml
  def create
    @bookmark_site = BookmarkSite.new(params[:bookmark_site])
    @bookmark_site.user = current_user

    respond_to do |format|
      if @bookmark_site.save_bookmark
        if @bookmark_site.existing_site?
          flash[:notice] = 'Bookmark was successfully updated.'
        else
          flash[:notice] = 'Bookmark was successfully created.'
        end
          
        format.html { redirect_to bookmark_sites_path }
        format.xml  { render :xml => @bookmark_site, :status => :created, :location => @bookmark_site }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bookmark_site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bookmark_sites/1
  # PUT /bookmark_sites/1.xml
  def update
    @bookmark_site = BookmarkSite.find(params[:id])

    respond_to do |format|
      if @bookmark_site.update_attributes(params[:bookmark_site])
        flash[:notice] = 'Bookmark was successfully updated.'
        format.html { redirect_to bookmark_sites_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bookmark_site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmark_sites/1
  # DELETE /bookmark_sites/1.xml
  def destroy
    @bookmark_site = BookmarkSite.find(params[:id])
    @bookmark_site.destroy

    respond_to do |format|
      format.html { redirect_to(bookmark_sites_url) }
      format.xml  { head :ok }
    end
  end
end
