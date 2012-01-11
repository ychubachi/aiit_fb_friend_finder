FACEBOOK_SCOPE = 'friends_education_history, friends_work_history'

class OauthController < ApplicationController
  def new
    puts 'GET /oauth/new'
    session[:at] = nil
    session[:return_to] ||= '/'
    redirect_to authenticator
      .authorize_url(:scope => FACEBOOK_SCOPE, :display => 'page')
  end

  def show
    puts 'GET /oauth'
    mogli_client = Mogli::Client
      .create_from_code_and_authenticator(params[:code],authenticator)
    session[:at] = mogli_client.access_token
    redirect_to session[:return_to]
  end

  def authenticator
    @authenticator ||= Mogli::Authenticator.new(ENV["FACEBOOK_APP_ID"], 
                                         ENV["FACEBOOK_SECRET"], 
                                         oauth_url)
  end
end
