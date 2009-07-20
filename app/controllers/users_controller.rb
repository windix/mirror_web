class UsersController < ApplicationController

  before_filter :require_invitation_token, :only => [ :new, :create ]

  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!" #  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    
    if (params[:user][:password].blank? && params[:user][:password_confirmation].blank?)
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update_attributes(params[:user])
      flash[:notice] = "Profile was successfully updated."
      redirect_to(@user)
    else
      render :action => 'edit'
    end
  end

  private

  def require_invitation_token
    if action_name == 'new' 
      if params[:invitation_token] 
        session[:invitation_token] = params[:invitation_token]
      else
        session[:invitation_token] = nil
      end
    end

    unless valid_invitation_token?(session[:invitation_token])
      flash.now[:error] = "Sorry, currently new user registration is not open to public."
      render :action => 'new' 
    end
  end

  def valid_invitation_token?(token)
    true if token == "12345"
  end

end
