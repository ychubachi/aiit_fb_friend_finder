# -*- coding: utf-8 -*-
require 'signed_request'

class FinderController < ApplicationController
  include SignedRequest

  # for Facebook pagetab
  # GET /finder
  # GET /finder.json
  def show
    puts "request['signed_request']=#{request['signed_request']}"
    if request['signed_request']
      sr = parse_signed_request(request, ENV["FACEBOOK_SECRET"])
      puts sr
      if sr["page"] && sr["page"]["liked"] == false
        redirect "https://#{request.env['HTTP_HOST']}/finder/message"
        return
      end
    end

    # Authorication
    redirect_to new_oauth_path and return unless session[:at]

    # puts 'Starting this session'
    t1 = Time.now
    @client = Mogli::Client.new(session[:at])
    @app     = Mogli::Application.find(ENV["FACEBOOK_APP_ID"], @client)

    # 情報を取得します
    # puts 'Getting the user information'
    t1 = Time.now
    @user    = Mogli::User.find("me", @client,
                                'username', 'name', 'education', 'work')
    t2 = Time.now
    diff = t2 - t1
    # puts "#{diff} sec"

    # puts 'Getting the friends information'
    t1 = Time.now
    # cache = settings.cache.get(@user.id)
    # if cache
    #   @friends = Marshal.load(cache)
    # else
      @friends = Mogli::User.find("me/friends", @client,
                                  'name', 'education', 'work')
    #  cache = Marshal.dump(@friends)
    #  settings.cache.set(@user.id, cache)
    # end
    @friends << @user
    t2 = Time.now
    diff = t2 - t1
    # puts "#{diff} sec"

    # 検索対象となるページのIDです
    official_ids = ['154020014683759']
    unofficial_ids = ['105671249467315',
                      '110072279074175',
                      '139942212709945',
                      '146753942064399',
                      '190561804319451',
                      '116082118405433']
    all_ids = official_ids + unofficial_ids

    # 自分の学歴／職歴を調べます
    @official = false
    @unofficial = false
    if @user.education
      @user.education.each do |e|
        if official_ids.include?(e.school.id)
          @official = true
        end
        if unofficial_ids.include?(e.school.id)
          @unofficial = true
        end
      end
    end
    if @user.work
      @user.work.each do |e|
        if official_ids.include?(e.employer.id)
          @official = true
        end
        if unofficial_ids.include?(e.employer.id)
          @unofficial = true
        end
      end
    end

    # 友達の学歴／職歴を調べます
    @aiit_friends = Hash.new
    @friends.each do |friend|
      if friend.education
        friend.education.each do |e|
          if all_ids.include?(e.school.id)
            school_year = e.year ? e.year.name : ''
            @aiit_friends[school_year] ||= Hash.new
            @aiit_friends[school_year][friend.id] = friend
          end
        end
      end
    end
    @aiit_friends = @aiit_friends.sort
    # puts @aiit_friends

    @aiit_workers = Hash.new
    @friends.each do |friend|
      if friend.work
        friend.work.each do |e|
          if all_ids.include?(e.employer.id)
            @aiit_workers[friend.id] = friend
          end
        end
      end
    end
    # puts @aiit_workers
    
    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # for Facebook canvas
  def create
    puts 'POST /finder'
    redirect_to finder_url
  end

  def message
    respond_to do |format|
      format.html # message.html.haml
    end
  end
  
end
