require 'rchardet'
require 'rest_client'
require 'iconv'
require 'cgi'
require 'url_utils'

class BookmarkSitesController < ApplicationController
  before_filter :login_required, :only => [ :new_url, :new, :edit, :create, :update, :destroy ]

  # GET /bookmarks
  def index
    if logged_in?
      @bookmarks = BookmarkSite.all_for_user(current_user).paginate :page => params[:page]
    else
      @bookmarks = BookmarkSite.all.paginate :page => params[:page]
    end
    
    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks)

    tag_cloud
  end

  # GET /bookmarks/1/versions
  def versions
    @bookmark = BookmarkSite.find(params[:id])

    @bookmarks = @bookmark.versions(current_user).paginate :page => params[:page]
    @date_groups, @date_groups_order = BookmarkSite.group_bookmarks_by_date(@bookmarks, :last_modified)

    tag_cloud_for_versions(@bookmarks)
  end

  # GET /bookmarks/1
  # TODO: not in use so far
  def show
    @bookmark_site = BookmarkSite.find(params[:id])
  end

  # GET /bookmarks/new_url
  def new_url
  end

  # GET /bookmarks/new
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

    if @bookmark_site = BookmarkSite.version_exists?(url, current_user.id)
      render :action => "edit"
    else
      @bookmark_site = BookmarkSite.new(:url => url, :title => title)
      @bookmark_site.tag_list = @delicious.suggest_tags(url).join(", ")
    end
  end

  # GET /bookmarks/1/edit
  def edit
    @bookmark_site = BookmarkSite.find(params[:id])
  end

  # POST /bookmarks
  def create
    @bookmark_site = BookmarkSite.new(params[:bookmark_site])
    @bookmark_site.user = current_user
    @bookmark_site.fetch_status = "UNFETCHED"
    
    if @bookmark_site.save
      Delayed::Job.enqueue(MirrorJob.new(@bookmark_site.id))
      
      flash[:notice] = t('bookmarks.msg_bookmark_queued')
      redirect_to bookmark_sites_path
    else
      render :action => "new"
    end
  end

  # PUT /bookmarks/1
  def update
    @bookmark_site = BookmarkSite.find(params[:id])
    
    if @bookmark_site.update_attributes(params[:bookmark_site])
      flash[:notice] = t('bookmarks.msg_bookmark_updated')
      redirect_to bookmark_sites_path
    else
      render :action => "edit"
    end
  end

  # DELETE /bookmarks/1
  def destroy
    @bookmark_site = BookmarkSite.find(params[:id])
    @bookmark_site.destroy
    
    redirect_to bookmark_sites_url
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
