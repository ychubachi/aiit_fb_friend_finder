class FinderController < ApplicationController
  # GET /finder
  # GET /finder.json
  def show
    # @heroku = Heroku.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      # format.json { render json: @heroku }
    end
  end
  
end
