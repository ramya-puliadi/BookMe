class UsersController < ApplicationController

  before_filter :set_current_user, :only=> ['show', 'edit', 'update', 'delete']
  def user_params
    params.require(:user).permit(:first_name,:last_name,:password,:user_id, :email, :password_confirmation)
  end
  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update 
    @info = user_params
    puts user_params
    puts @info
    @current_user = User.find params[:id]
    puts "cool"
    puts @current_user
    puts "cool"
    if @current_user.update_attributes(@info)
      puts @current_user
      redirect_to mybooks_path
    else
      redirect_to edit_user_path
      puts "sudhfblahbgslkdfbglsdfhbgldbg"
    end

  end
  
  def new
    # default: render 'new' template
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.update_attribute(:books_sold, 0)
      @user.update_attribute(:books_bought, 0)
      flash[:notice] = "Welcome #{@user.user_id}. Your account has been created."
      redirect_to login_path
    else
      render 'new'
    end
  end
end
