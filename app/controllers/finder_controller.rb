# -*- coding: utf-8 -*-
require 'signed_request'

class FinderController < ApplicationController
  include SignedRequest

  # 検索対象となるページのIDです
  @@official_ids = ['154020014683759']
  @@unofficial_ids = ['105671249467315',
                      '110072279074175',
                      '139942212709945',
                      '146753942064399',
                      '190561804319451',
                      '116082118405433']
  @@all_ids = @@official_ids + @@unofficial_ids

  # for Facebook pagetab
  # GET /finder
  # GET /finder.json
  def show
    puts '=' * 8 + ' GET /finder'
    # Check 'Like'
    if request['signed_request']
      sr = parse_signed_request(request, ENV["FACEBOOK_SECRET"])
      puts sr
      if sr["page"] && sr["page"]["liked"] == false
        # redirect_to "https://#{request.env['HTTP_HOST']}/finder/message" and return
        redirect_to message_finder_url and return
      end
    end

    # Authorication
    redirect_to new_oauth_path and return unless session[:at]
    # Find Friends
    find
    # Render
    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # for Facebook canvas
  def create
    puts '=' * 8 + ' POST /finder'
    redirect_to finder_url
  end

  def education
    # Authorication
    session[:return_to] = request.url
    redirect_to new_oauth_path and return unless session[:at]
    # Find Friends
    find_education
    # Render
    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @aiit_friends }
    end
  end

  def work
    # Authorication
    session[:return_to] = request.url
    redirect_to new_oauth_path and return unless session[:at]
    # Find Friends
    find_work
    # Render
    respond_to do |format|
      format.html
      format.json { render json: @aiit_workers }
    end
  end

  # Show message to non-liked user
  def message
    respond_to do |format|
      format.html # message.html.haml
    end
  end

  def find
    # puts 'Starting this session'
    @client = Mogli::Client.new(session[:at])
    @app     = Mogli::Application.find(ENV["FACEBOOK_APP_ID"], @client)

    # 情報を取得します
    # puts 'Getting the user information'
    @user    = Mogli::User.find("me", @client,
                                'username', 'name', 'education', 'work')

    # 自分の学歴／職歴を調べます
    @official = false
    @unofficial = false
    if @user.education
      @user.education.each do |e|
        if @@official_ids.include?(e.school.id)
          @official = true
        end
        if @@unofficial_ids.include?(e.school.id)
          @unofficial = true
        end
      end
    end
    if @user.work
      @user.work.each do |e|
        if @@official_ids.include?(e.employer.id)
          @official = true
        end
        if @@unofficial_ids.include?(e.employer.id)
          @unofficial = true
        end
      end
    end
  end

  :private

  def find_education
    # 友達の学歴/職歴を取得します
    facebook

    # 友達の学歴を調べます
    time_diff 'Checking AIIT friends in education' do
      @aiit_friends = Hash.new
      @friends.each do |friend|
        if friend.education
          friend.education.each do |e|
            if @@all_ids.include?(e.school.id)
              school_year = e.year ? e.year.name : ''
              @aiit_friends[school_year] ||= Hash.new
              @aiit_friends[school_year][friend.id] = friend
            end
          end
        end
      end
      @aiit_friends = @aiit_friends.sort
    end
  end

  def find_work
    # 友達の学歴/職歴を取得します
    facebook

    # 友達の職歴を調べます
    time_diff 'Checking AIIT friends in work' do
      @aiit_workers = Hash.new
      @friends.each do |friend|
        if friend.work
          friend.work.each do |e|
            if @@all_ids.include?(e.employer.id)
              @aiit_workers[friend.id] = friend
            end
          end
        end
      end
    end
  end

  def facebook
    time_diff 'Starting this session' do
      @client = Mogli::Client.new(session[:at])
      @app     = Mogli::Application.find(ENV["FACEBOOK_APP_ID"], @client)
    end
    
    time_diff 'Getting the user information' do
      @user    = Mogli::User.find("me", @client,
                                  'username', 'name', 'education', 'work')
    end

    time_diff 'Getting his/her friends information' do
      cache = Rails.cache.read(@user.id)
      if cache
        @friends = Marshal.load(cache)
      else
        @friends = Mogli::User.find("me/friends", @client,
                                    'name', 'education', 'work')
        Rails.cache.write(@user.id, Marshal.dump(@friends))
      end
    end
  end

  def time_diff message
    puts 'Start: ' + message
    t1 = Time.now
    yield
    t2 = Time.now
    diff = t2 - t1
    puts 
    puts 'End: ' + message + " in #{diff} sec"
  end
end
