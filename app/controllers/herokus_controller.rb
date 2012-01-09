class HerokusController < ApplicationController
  # GET /herokus
  # GET /herokus.json
  def index
    redirect_to new_oauth_path and return unless session[:at]

    user = Mogli::User.find("me",Mogli::Client.new(session[:at]))
    @user = user
    @posts = user.posts

    @herokus = Heroku.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @herokus }
    end
  end

  # GET /herokus/1
  # GET /herokus/1.json
  def show
    @heroku = Heroku.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @heroku }
    end
  end

  # GET /herokus/new
  # GET /herokus/new.json
  def new
    @heroku = Heroku.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @heroku }
    end
  end

  # GET /herokus/1/edit
  def edit
    @heroku = Heroku.find(params[:id])
  end

  # POST /herokus
  # POST /herokus.json
  def create
    @heroku = Heroku.new(params[:heroku])

    respond_to do |format|
      if @heroku.save
        format.html { redirect_to @heroku, notice: 'Heroku was successfully created.' }
        format.json { render json: @heroku, status: :created, location: @heroku }
      else
        format.html { render action: "new" }
        format.json { render json: @heroku.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /herokus/1
  # PUT /herokus/1.json
  def update
    @heroku = Heroku.find(params[:id])

    respond_to do |format|
      if @heroku.update_attributes(params[:heroku])
        format.html { redirect_to @heroku, notice: 'Heroku was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @heroku.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /herokus/1
  # DELETE /herokus/1.json
  def destroy
    @heroku = Heroku.find(params[:id])
    @heroku.destroy

    respond_to do |format|
      format.html { redirect_to herokus_url }
      format.json { head :ok }
    end
  end
end
