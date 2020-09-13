# # Example config.rb for CuttingEdge
# 
# module CuttingEdge
#   REFRESH_SCHEDULE = '1h'  # How often to run workers to check for changes to dependency status. Examples of valid values: '10d', '10m', etc.
#   SERVER_HOST = 'mydependencymonitoring.com' # At what domain is this CuttingEdge instance running? Defaults to 'localhost'
#   SERVER_URL = "https://#{SERVER_HOST}" # The URL used to refer to this CuttingEdge instance, for instance in e-mails. Defaults to 'http://#{SERVER_HOST}' 
# 
#   MAIL_TO = false # Default address to send email to. If set to false, don't send any e-mails except for repositories that have their 'email:' attribute set in projects.yml
#   MAIL_FROM = "cutting_edge@#{SERVER_HOST}" # From Address used for sending e-mails. Default: "cutting_edge@#{SERVER_HOST}" 
# 
#   LAST_VERSION_TIMEOUT = 5 # Number of seconds after which to fail when trying to determine the latest version for a dependency.
# 
#   BADGE_COLORS = {
#    ok: 'blue',
#    outdated_patch: '#dfb317',
#    outdated_minor: '#fe7d37',
#    outdated_major: '#e05d44',
#    unknown: '#9f9f9f'
#   } # Redefine the colors used in SVG badges
# 
#   # The following will allow you to define projects on your own GitLab instance in projects.yml
#   # If you want to use the key 'myserver' in projects.yml, your repository class must be named MyserverRepository
#   require './lib/cutting_edge/repo.rb'
#   class MyserverRepository < GitlabRepository # The naming here is .
#     HOST = 'https://myserver.com/'
#     # This will allow you to use your own GitLab instance in projects.yml like so:
#     # myserver:
#     #   orgname:
#     #     projectname:
#   end
# end