require 'rubygems'
require 'neography'
require 'neography/tasks'


desc "One time task to setup on Heroku"
task :create do
  sh "bundle exec heroku create neo-ivr"
  sh "bundle exec heroku config:set TWILIO_SID=" + ENV["TWILIO_SID"]
  sh "bundle exec heroku config:set TWILIO_TOKEN=" + ENV["TWILIO_TOKEN"]
  sh "git push heroku master"
  sh "bundle exec heroku addons:add graphenedb --version v213"
  sh "bundle exec heroku run rake db:migrate"
  sh "bundle exec heroku run rake db:populate"
end

namespace :db do
  task :migrate do
    neo = Neography::Rest.new(ENV["GRAPHENEDB_URL"] || "http://localhost:7474")    
    neo.create_unique_constraint("User", "number")
    neo.create_unique_constraint("Page", "url")
    neo.create_schema_index("Event", ["session"])  
  end
  task :populate do
    neo = Neography::Rest.new(ENV["GRAPHENEDB_URL"] || "http://localhost:7474")    
    neo.commit_transaction(["MERGE (u:Page {url: {url}})", {:url => "/"},
                           "MERGE (u:Page {url: {url}})", {:url => "/billing"},
                           "MERGE (u:Page {url: {url}})", {:url => "/maintenance"},
                           "MERGE (u:Page {url: {url}})", {:url => "/representative"},
                           "MERGE (u:Page {url: {url}})", {:url => "/notimplemented"},
                           "MERGE (u:Page {url: {url}})", {:url => "/representative"},
                           "MERGE (u:Page {url: {url}})", {:url => "/payment"},
                           "MERGE (u:Page {url: {url}})", {:url => "/address"},
                           "MERGE (u:Page {url: {url}})", {:url => "/other_billing"},
                           "MERGE (u:Page {url: {url}})", {:url => "/heat"},
                           "MERGE (u:Page {url: {url}})", {:url => "/plumbing"},
                           "MERGE (u:Page {url: {url}})", {:url => "/other_service"}])

  end

end