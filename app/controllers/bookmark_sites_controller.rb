require 'rchardet'
require 'rest_client'
require 'iconv'
require 'cgi'
require 'url_utils'

class BookmarkSitesController < ApplicationController
  before_filter :login_required, :only => [ :new_url, :new, :edit, :create, :update, :destroy ]

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

  def new_url
  end

  # GET /bookmark_sites/new
  # GET /bookmark_sites/new.xml
  def new
    if params[:new_url]
      unless url = URLUtils.validate_and_format_url(params[:new_url])
        flash[:notice] = t('bookmarks.msg_invalid_url', :url => params[:new_url])
        redirect_to new_url_bookmark_sites_path
        return
      else
        title = get_page_title(url)
      end
    elsif params[:url]
      url = params[:url]
      title = params[:title]
    end

    @bookmark_site = BookmarkSite.new(:url => url, :title => title)
    
    if url
      @bookmark_site.tag_list = @delicious.suggest_tags(url).join(", ")
    end

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
          flash[:notice] = t('bookmarks.msg_bookmark_updated')
        else
          flash[:notice] = t('bookmarks.msg_bookmark_created')
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
        flash[:notice] = t('bookmarks.msg_bookmark_updated')
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

  private

  def get_page_title(url)
    # TODO: user_agent
    content = RestClient.get(URLUtils.escape_url(url), :accept => "*/*") 

    if content =~ /<\s*title[^>]*>(.*?)<\/title>/im
      title = $1.strip
      
      cd = CharDet.detect(title)
      encoding = cd['encoding']
      encoding = "GBK" if encoding == "GB2312" 
      title = Iconv.iconv('utf-8', encoding, title).to_s unless encoding == "utf-8"

      CGI.unescapeHTML title
    end
  end
end
