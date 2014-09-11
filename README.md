neo_ivr
=======

Sample Neo4j IVR with Twilio

Sign up on Twilio for an account
Create a new app and point it to the URL on Heroku where you are deploying (use GET).
Configure your Twilio phone number to point to your new Twilio app.
Set your local ENV["TWILIO_SID"] and ENV["TWILIO_TOKEN"] environment variables.

run:
	rake create

For Twilio Documentation see https://www.twilio.com/docs/api/twiml
	
Sounds played from:
http://www.moviesoundclips.net/sound.php?id=70
