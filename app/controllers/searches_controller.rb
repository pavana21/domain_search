class SearchesController < ApplicationController
  require 'rest_client'
  require 'json'
  
  def index
  end

  def find_domain_name
    @country_codes = %w[.com .in .net .co.in .org]
    @domain = params[:search_text]
    @domain_names = []
    @flag = []
    @country_codes.each do |cc|
      @cc = cc
      @domain_names << "#{@domain + @cc}"
      if(Search.where(domain_name: "#{@domain + @cc}").length > 0) #checks whether domain exists in database or not
        @flag << true
        puts @flag
      else
        get_url_data
        puts @result
        if @result["WhoisRecord"].nil? || @result["WhoisRecord"]["dataError"]
          @flag << false
          puts @flag
        else
          @search = Search.create(search_text: params[:search_text], domain_name: "#{@domain + @cc}")
          @flag << true
          puts @flag
        end
      end
    end
    delete_past_week_data
    respond_to do |format|
      format.json do
        render :json => {domain: @domain_names, results: @flag}
      end
    end
  end
  
  def get_url_data
    url = "http://www.whoisxmlapi.com/whoisserver/WhoisService?domainName=#{@domain + @cc}&outputFormat=json"
    response = RestClient.get(url)
    data = response
    @result = JSON.parse(data)
  end
  
  def delete_past_week_data
    Search.all.select { |s| s.delete if(((Date.today) - s.created_at.to_date) > 7) }
  end
end