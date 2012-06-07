class SearchesController < ApplicationController
  require 'rest_client'
  require 'json'
  def index
  end

  def action
    @country_codes = %w[.com .in .net .co.in .org]
    @domain = params[:search_text]
    @domain_names = []
    @results = []
    @country_codes.each do |cc|
      @domain_names << "#{@domain + cc}"
      if(Search.where(domain_name: "#{@domain + cc}").length > 0) #checks whether domain exists in database or not
        @results << true
        puts @results
      else
        url = "http://www.whoisxmlapi.com/whoisserver/WhoisService?domainName=#{@domain + cc}&outputFormat=json"
        response = RestClient.get(url)
        data = response
        result = JSON.parse(data)
        puts result
        if result["WhoisRecord"].nil? || result["WhoisRecord"]["dataError"]
          @results << false
          puts @results
        else
          @search = Search.create(search_text: params[:search_text], domain_name: "#{@domain + cc}")
          @results << true
          puts @results
        end
      end
    end
    # Deletes the Database after one week expiry
    Search.all.select { |s| s.delete if(((Date.today) - s.created_at.to_date) > 7) }
    respond_to do |format|
      format.json do
        render :json => {domain: @domain_names, results: @results}
      end
    end
  end
end