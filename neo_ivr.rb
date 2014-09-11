require "rubygems"
require "sinatra"
require "twilio-ruby"
require "neography"

configure do
  $neo = Neography::Rest.new(ENV["GRAPHENEDB_URL"] || "htto://localhost:7474")      
  
  # Twilio Credentials:
  account_sid = ENV["TWILIO_SID"] 
  auth_token = ENV["TWILIO_TOKEN"]
  
  # set up a client to talk to the Twilio REST API
  $twilio = Twilio::REST::Client.new account_sid, auth_token
end

before do
  content_type "text/xml", :charset => "utf-8"  
end

get "/" do
  $neo.commit_transaction(["MERGE (u:User {number: {number}})", {:number => request["From"]}])
  $neo.commit_transaction(["MATCH (u:User {number: {number}}), (p:Page {url: {url}}) 
    MERGE (u)-[:DIALED]->(e:Event {session: {session}, url: {url}})-[:ON]->(p)
    RETURN e", 
    {:number => request["From"],
     :url => "/",
     :session => request["CallSid"]}
     ])
  response = Twilio::TwiML::Response.new do |r|
    r.Say "Thank you for calling the Neo4j I V R demo.", :voice => "alice"
    r.Gather :action => "/mainmenu", :numDigits => 1 do
      r.Say "For quality assurance purposes this call may be recorded", :voice => "alice"
      r.Say "For rent payment options and billing questions, press 1", :voice => "alice"
      r.Say "To submit a maintenance request, press 2", :voice => "alice"
      r.Say "For all other tenant related questions press 3", :voice => "alice"
      r.Say "To repeat this message press 9", :voice => "alice"
    end
    r.Say "Sorry, I didn\"t get your response.", :voice => "alice"
    r.Play "http://neo-ivr.herokuapp.com/" + "hello.mp3"
    r.Redirect "/", :method => "GET"
  end

  response.text
end

post "/mainmenu" do
  response = Twilio::TwiML::Response.new do |r|
    case params["Digits"]
      when "1"
        r.Redirect "/billing"
      when "2"
        r.Redirect "/maintenance"
      when "3"
        r.Redirect "/representative"
      when "9"
        r.Redirect "/", :method => "GET"
      else
        r.Redirect "/not_implemented"
      end
    end

  response.text
end

post "/billing" do
  add_event(request, "/billing")
  response = Twilio::TwiML::Response.new do |r|
    r.Gather :action => "/billing-input", :numDigits => 1 do
      r.Say "to make a payment over the phone with your checking account, debit or credit card, press 1 ", :voice => "alice"
      r.Say "for our rent mailing address, press 2", :voice => "alice"
      r.Say "for all other billing questions, press 3", :voice => "alice"
      r.Say "to return to the previous menu, press 0", :voice => "alice"
      r.Say "to repeat this message press 9", :voice => "alice"
    end
    r.Say "Sorry, I didn\"t get your response.", :voice => "alice"
    r.Play "http://neo-ivr.herokuapp.com/" + "hello.mp3"
    r.Redirect "/billing"
  end  
  response.text  
end

post "/billing-input" do
  url = case params["Digits"]
          when "0" then "/"
          when "1" then "/payment"
          when "2" then "/address"
          when "3" then "/other_billing"  
          when "9" then "/billing"
          else "/not_implemented"
        end
  add_event(request, url)
  response = Twilio::TwiML::Response.new do |r|
    case params["Digits"]
      when "0"
        r.Redirect "/", :method => "GET"
      when "1"
        #payment
        r.Play "http://neo-ivr.herokuapp.com/" + "what.mp3"
        r.Hangup
      when "2"
        #address
        r.Play "http://neo-ivr.herokuapp.com/" + "bunk.mp3"
        r.Hangup        
      when "3"
        #other_billing
        r.Play "http://neo-ivr.herokuapp.com/" + "leaf.mp3"
        r.Hangup        
      when "9"
        r.Redirect "/billing"
      else
        r.Redirect "/not_implemented"
      end
    end

  response.text
end

post "/maintenance" do
  add_event(request, "/maintenance")
  response = Twilio::TwiML::Response.new do |r|
    r.Gather :action => "/maintenance-input", :numDigits => 1 do
      r.Say "if your heat is out, press 1 ", :voice => "alice"
      r.Say "if there is a problem with your plumbing, press 2", :voice => "alice"
      r.Say "for all other maintenance questions, press 3", :voice => "alice"
      r.Say "to return to the previous menu, press 0", :voice => "alice"
      r.Say "to repeat this message press 9", :voice => "alice"
    end
    r.Say "Sorry, I didn\"t get your response.", :voice => "alice"
    r.Play "http://neo-ivr.herokuapp.com/" + "hello.mp3"
    r.Redirect "/maintenance"
  end  
  response.text  
end

post "/maintenance-input" do
    url = case params["Digits"]
          when "0" then "/"
          when "1" then "/heat"
          when "2" then "/plumbing"
          when "3" then "/other_maintenance"  
          when "9" then "/maintenance"
          else "/not_implemented"
        end
  add_event(request, url)
  response = Twilio::TwiML::Response.new do |r|
    case params["Digits"]
      when "0"
        r.Redirect "/", :method => "GET"
      when "1"
        #heat
        r.Play "http://neo-ivr.herokuapp.com/" + "awesome.mp3"
        r.Hangup        
      when "2"
        #plumbing
        r.Play "http://neo-ivr.herokuapp.com/" + "misbehave.mp3"
        r.Hangup        
      when "3"
        #other_maintenance
        r.Play "http://neo-ivr.herokuapp.com/" + "nopower.mp3"
        r.Hangup        
      when "9"
        r.Redirect "/maintenance"
      else
        r.Redirect "/not_implemented"
      end
    end
  response.text
end

post "/representative" do
  add_event(request, "/representative")
  response = Twilio::TwiML::Response.new do |r|
    r.Play "http://neo-ivr.herokuapp.com/" + "theme.mp3"
    r.Hangup    
  end
  response.text
end

post "/not_implemented" do
  add_event(request, "/not_implemented")
  response = Twilio::TwiML::Response.new do |r|
    r.Say "I am sorry, that feature has not been implemented yet.", :voice => "alice"
    r.Play "http://neo-ivr.herokuapp.com/" + "baby.mp3"
    r.Hangup    
  end
  response.text
end

def add_event(request, url)
    $neo.commit_transaction(["MATCH (old:Event {session: {session}})<-[:PREV*0..]-(latest)
      WHERE NOT(latest<-[:PREV]-())
      WITH latest
      LIMIT 1
      CREATE (latest)<-[:PREV]-(e:Event {session: {session}, url: {url}})
      WITH e
      MATCH (u:User {number: {number}}), (p:Page {url: {url}})
      CREATE (u)-[:DIALED]->(e)-[:ON]->(p)
      RETURN e", 
    {:number => request["From"],
     :url => url,
     :session => request["CallSid"]}
     ]) 
end

get "/data.json" do
  result = $neo.commit_transaction("MATCH (p:Page) RETURN p.url")
  nodes = result["results"][0]["data"].collect{|d| d["row"][0]}.flatten
  nodes += ["/hangup"]  

  result = $neo.commit_transaction("MATCH path=(p:Page {url:'/'})<-[:ON]-()-[:PREV*0..3]-()
                           RETURN EXTRACT(v in NODES(path)[1..LENGTH(path)+1] | v.url), count(path)
                           ORDER BY count(path) DESC
                           LIMIT 10")
  links = []                         
  result["results"][0]["data"].collect{|d| {:links => d["row"][0].last(2), :count => d["row"][1]}}.each do |link|
    source = nodes.index(link[:links][0])
    target = nodes.index(link[:links][1] || "/hangup")
    links += [{:source => source, :target => target, :value => link[:count]}]
  end

  nodes = nodes.collect{|n| {:name => n}}                           
  {:nodes => nodes, :links => links }.to_json  
end