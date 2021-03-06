class BooksController < ApplicationController
  before_filter :set_current_user
  helper_method :sort_column, :sort_direction
  def book_params
    params.require(:book).permit(:title, :author, :isbn, :department, :course, :quality, :price, :auction_start_price, :auction_time, :description, :image, :keyword, :time_left, :bid_price, :bidder_id)
  end
  
  def show #displayed when user clicks on book title link
    id = params[:id] # retrieve book ID from URI route
    @book = Book.find(id) # look up book by unique ID
    Book.update_time(id)
    if Tag.find_by(book_id: @book.id) #getting the keywords if there are any
      @keywords = Array.new
      Tag.find_each do |keyword|
        if keyword.book_id == @book.id
          @keywords << keyword
        end
      end
    else
      @keywords = { }
    end # will render app/views/books/show.<extension> by default
  end

  def index #rendered when user clicks on 'allBooks'
    sort = params[:sort] || session[:sort]
    @books = Book.order(sort_column + " " + sort_direction)
    @books = Book.search(params[:search]).order(sort_column + ' ' + sort_direction)-Book.where(status:"sold")
    @books.each do |book|
      Book.update_time(book.id)
    end
    session[:session_token]= @current_user.user_id
  end

  def remove_purchase
    @book = Book.find(params[:id])
    Tag.delete_all book_id: @book.id
    @book.destroy
    flash[:notice] = "'#{@book.title}' deleted."
    redirect_to mybids_path
  end

  def mybooks #routed here when user hits "mybooks" button and renders mybooks view
    #puts "IN MY BOOKS!!!!!!!!!!!!!!!!!"
    @user = User.find(@current_user.id.to_s)
    @books = @user.books.search(params[:search])-Book.where(status:"sold")
    @books_sold = @user.books.search(params[:search]).where(status:"sold")
    params.each do |p|
      #puts p.to_s
    end
  
  end
  
  def mybids #routed here when user hits "mybooks" button and renders mybooks view
    @user = User.find(@current_user.id.to_s)
    #@books = @user.books.search(params[:search])
    @books = Book.where(bidder_id:@user.user_id).where(status:"auction")
    @books.each do |book| #update the bid time
      Book.update_time(book.id)
      #puts book.bid_price
    end
    
    #getting my bids
    @mybids=Array.new
    @bids=Bid.where(user_id:@current_user.id)
    if !@bids.empty?
      @bids.each do |bid|
        book=Book.find(bid.book_id)
        if bid.notification
          color='red'
          bid.update_attribute(:notification, false)
        else 
          color='normal'
        end
        @mybids << {:book_title => book.title, :book_author => book.author, :book_isbn => book.isbn, :bid_price => bid.bid, :bid_status => bid.status, :time_left => book.time_left, :image => book.image, :color => color, :bid_id => bid.id, :book_id => book.id}
      end
    end
    @booksBought = Book.where(bidder_id:@user.user_id).where(status:"sold")
    params.each do |p|
      #puts p.to_s
    end
  end

  def new #routed here when user hits 'add book' button and renders new view
    #puts "NEEEEEWWWWWW"
    keywords={"0"=>""}
    @book={:title => "", :author => "", :isbn => "", :department => "", :course => "", :price => "", :auction_start_price => "", :auction_time => "", :quality => "", :image => "nobook.gif", :description => "", :keyword => keywords, :time_left=> ""}

    # default: render 'new' template
  end


  def search_open_lib #routed here when user looks up book isbn and renders new view
    @isbn = params[:book][:isbn_open_lib]
    @book=Book.open_lib_find_book(@isbn)

    if @book.empty?
      flash[:warning] = "Book not found in database!"
    end
    keywords={"0"=>""}
    @book[:keyword]=keywords
    render new_book_path 
  end


  def create #routed here when user saves changes on added book and redirects to index
    @info = book_params
    keywords=params[:book][:keyword]
    #puts "IN CREATE!!"
    if @info[:image].to_s.empty?
      @info[:image]="nobook.gif"
    end

    @info[:isbn]=@info[:isbn].gsub(/[-' ']/,'')
#    if @info[:price]==""
#      @info[:price]="0.00"
#    end
    if @info[:auction_start_price]==""
      @info[:auction_start_price]=@info[:price]
    end
    @info[:bid_price]=@info[:auction_start_price]
    @info[:status]= "auction"

    @info["auction_time(1i)"]=params["book"]["auction_time"]["{}(1i)"]
    @info["auction_time(2i)"]=params["book"]["auction_time"]["{}(2i)"]
    @info["auction_time(3i)"]=params["book"]["auction_time"]["{}(3i)"]
    @info["auction_time(4i)"]=params["book"]["auction_time"]["{}(4i)"]
    @info["auction_time(5i)"]=params["book"]["auction_time"]["{}(5i)"]
    testbook = Book.new(@info)

    if(testbook.valid?)
      book = @current_user.books.create!(@info)
      flash[:notice] = "#{book.title} was successfully added."
      keywords.each do |key, value| #adding all of the keywords to the keyword database
        Tag.create!({:book_id => book.id, :tag => value})
        #puts "created keyword: " + value
      end
      Book.update_time(book.id)
      redirect_to mybooks_path
    else
#      @info[:auction_time]=@info[:auction_time].to_s
      @book=@info
      @book[:keyword]=keywords
      messages = testbook.errors.full_messages
      flash[:warning] = messages.join("<br/>").html_safe
      #puts "MESSAGES ARE:::::::"
      #puts messages
      render new_book_path
    end
  end



  def edit #routes here when you click the 'edit' button from the mybooks view and renders edit view
    @book = Book.find params[:id]
    @keywords = []
    #puts "is empty?"
    #puts @keywords.empty?
    if Tag.find_by(book_id: @book.id.to_s) #getting the keywords if there are an
      #puts "id is: " +  @book.id.to_s
      Tag.find_each  do |keyword|
        if !keyword.tag.empty?
          if keyword.book_id == @book.id
            #puts "in if keyword matches"
             @keywords << keyword
          end
        end
      end
    end
  end
  

  def update #routes here when you click 'Update info' button on edit view and redirects show
    @info = book_params
    keywords=params[:book][:keyword]
    @info[:isbn]=@info[:isbn].gsub(/[-' ']/,'')
    
    @info["auction_time(1i)"]=params["book"]["auction_time"]["{}(1i)"]
    @info["auction_time(2i)"]=params["book"]["auction_time"]["{}(2i)"]
    @info["auction_time(3i)"]=params["book"]["auction_time"]["{}(3i)"]
    @info["auction_time(4i)"]=params["book"]["auction_time"]["{}(4i)"]
    @info["auction_time(5i)"]=params["book"]["auction_time"]["{}(5i)"]
    
    #if @info[:price]==""
    #  @info[:price]="0.00"
    #end
    if @info[:auction_start_price]==""
      @info[:auction_start_price]="0.00"
    end
    testbook = Book.new(@info)
    if(testbook.valid?)
      @book = Book.find params[:id]
      @book.update_attributes!(@info)

      Tag.delete_all(book_id: @book.id) #deleting all of the keysword for this book
       keywords.each do |key, value| #adding all of the keywords to the keyword database
          Tag.create!({:book_id => @book.id, :tag => value}) #adding in the new keywords
      end
      flash[:notice] = "#{@book.title} was successfully updated."
      Book.update_time(@book.id)
      redirect_to book_path(@book)
    else 
      messages = testbook.errors.full_messages
      flash[:warning] = messages.join("<br/>").html_safe
      redirect_to edit_book_path
    end
  end

  def destroy #routes here when you click 'delete' on mybooks view and redirects to index method
    @book = Book.find(params[:id])
    Tag.delete_all book_id: @book.id
    @book.destroy
    flash[:notice] = "'#{@book.title}' deleted."
    redirect_to mybooks_path
  end

  def buy_now
    @book = Book.find(params[:id])
    if @book[:status]=="sold"
      flash[:notice] = "Sorry '#{@book.title}' already sold."
      redirect_to book_path
    else
      @book.update_attribute(:bidder_id, @current_user[:user_id])
      @book.update_attribute(:bid_price, @book.price)
      @book.update_attribute(:status, "sold")
      @book.update_attribute(:notification, true)
      
      if(Bid.exists?(:book_id => @book.id))
        @bid = Bid.where(:book_id => @book.id)
        @bid.each do |bid|
          bid.update_attribute(:status, "sold") #change status to sold
          if @current_user.id != bid.user_id
            bid.update_attribute(:notification, true) #give notification to everyone except the person who bought it
          end
        end
        #Bid.create({:user_id => @current_user.id, })
      end
      
      bidder = User.find_by_user_id(@book.bidder_id)
      seller = User.find(@book.user_id)

      bidder.update_attribute(:books_bought, (bidder.books_bought)+1)
      seller.update_attribute(:books_sold, (seller.books_sold)+1)
      
      flash[:notice] = "You have purchased "+@book.title+". Thank you!"
      redirect_to books_path
    end
  end
  
  def make_bid #should move to bids controller, really
    @book = Book.find(params[:id])
    @info = book_params
    if @info[:status]=="sold"
      flash[:notice] = "Sorry '#{@book.title}' already sold."
      redirect_to book_path
    else
      if (@info[:bid_price]=~/\A[0-9]+\.?[0-9]*\z/) == 0
        if @info[:bid_price].to_f > @book[:bid_price].to_f
          if @book[:status]=="auction"
            @book.update_attribute(:bid_price, @info[:bid_price])
            @book.update_attribute(:bidder_id, @current_user[:user_id])
            @book.update_attribute(:notification, true)
            #get id of this usr
            #puts "-------------------BOOKS PARARMS ARE---------------"
            #puts @book.id.to_s
            #puts @current_user.id
            #puts @info[:bid_price]
            #alert potential other user that they may be out of the bid
            if Bid.exists?(:book_id => @book.id, :user_id => @current_user.id) #if this users bid already exist
              @bid = Bid.find_by_book_id_and_status(@book.id,"highest bid")
              @bid.update_attribute(:notification, true) #give them a notification
              @bid.update_attribute(:status, "out of bid") #change the status of their bid
              @mybid=Bid.find_by_book_id_and_user_id(@book.id, @current_user.id)
              @mybid.update_attribute(:bid, @info[:bid_price]) #just update the bid
              @mybid.update_attribute(:status, "highest bid") #just update the status
              @mybid.update_attribute(:notification, false) #just update the status
              
            else
              if (!Bid.where(:book_id => @book.id, :status=>"highest bid").blank?)
                @bid = Bid.find_by_book_id_and_status(@book.id,"highest bid")
                @bid.update_attribute(:notification, true) #give them a notification
                @bid.update_attribute(:status, "out of bid") #change the status of their bid
              end
              #puts "in else!!!!"
              Bid.create({:book_id => @book.id, :user_id => @current_user.id, :bid =>  @info[:bid_price], :notification => false}) #adding bid to the bid database
            end
            #puts "testing bids!!\n\n"
            @bid=Bid.all
            @bid.each do |bid|
              #puts "user_id: " + bid.user_id.to_s + " book_id: "+ bid.book_id.to_s + " bid: " + bid.bid.to_s + " notification: " + bid.notification.to_s + " bid status: " + bid.status
            end
            flash[:notice] = "$"+@book.bid_price+" bid made for "+@book.title
            redirect_to books_path
          else
            flash[:notice] = "Sorry, auction has ended."
            redirect_to book_path
          end  
        else
          flash[:notice] = "Bid must be greater than current bid."
          redirect_to book_path
        end
      else
        flash[:notice] = "Invalid bid price."
        redirect_to book_path
      end
    end
  end
  
  private
  def sort_column
    Book.column_names.include?(params[:sort]) ? params[:sort] : "title"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
