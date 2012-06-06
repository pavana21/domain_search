class SearchesController < ApplicationController
  require 'rest-client'

  def index 
  end

  def action
    @country_codes = [".in"] # etc. could move this to a config if needed
    @domain = params[:search_text]
    @domain_names = []
    puts "Domain: #{@domain}"
    @country_codes.each do |cc|
      @domain_names << "#{@domain + cc}"
      if(Search.where(domain_name: "#{@domain + cc}").length > 0)
        @x = true
      else
        url = "http://www.whoisxmlapi.com/whoisserver/WhoisService?domainName=#{@domain + cc}&outputFormat=json"
        response = RestClient.get(url)
        data = response.body
        result = JSON.parse(data)
        puts result
        puts result["WhoisRecord"].nil? || result["WhoisRecord"]["dataError"]
        if result["WhoisRecord"].nil? || result["WhoisRecord"]["dataError"]
          puts "Failure"
          @x = false
        else
          @search = Search.create(search_text: params[:search_text], domain_name: "#{@domain + cc}")
          puts "Success"
          puts @search
            @x = true
        end
      end
    end
    respond_to do |format|
      format.json do
        render :json => {domain: @domain_names, x: @x}
      end
    end
  end
end