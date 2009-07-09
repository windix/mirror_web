# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mirror_session',
  :secret      => '2c7358ffb8bb2d93248eed6d579b65cf86566f0b10acb9444381f91f19af477b468ea22b328bae6eb79b03e91e6bdb610ed17acabe9fc802c214e802e9c6acf9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
