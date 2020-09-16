# # Example config.rb for CuttingEdge
# # All the settings below are purely optional: they all have sane defaults.  
# 
# module CuttingEdge
#   REFRESH_SCHEDULE = '1h'  # How often to run workers to check for changes to dependency status. Examples of valid values: '10d', '10m', etc.
#   SERVER_HOST = 'mydependencymonitoring.com' # At what domain is this CuttingEdge instance running? Defaults to 'localhost'
#   SERVER_URL = "https://#{SERVER_HOST}" # The URL used to refer to this CuttingEdge instance, for instance in e-mails. Defaults to 'http://#{SERVER_HOST}' 
# 
#   MAIL_TO = 'mydeps@mymail.com'  # Default address to send email to. If set to false (=default!), don't send any e-mails except for repositories that have their 'email:' attribute set in projects.yml
#   MAIL_FROM = "cutting_edge@#{SERVER_HOST}" # From Address used for sending e-mails. Default: "cutting_edge@#{SERVER_HOST}" 
#   MAIL_TEMPLATE = <<EOF
#     Define your own ERB template for e-mail updates from CuttingEdge here!
#     Of course, you can also File.read it from a separate template file.
#     See lib/cutting_edge/templates/mail.html.erb for the default template, and the available variables.
# EOF
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
# # The following will allow you to define projects on your own GitLab or Gitea server in projects.yml
# # This will allow you to use the 'mygitlab' and 'mygitea' keys, respectively, in projects.yml
#   require './lib/cutting_edge/repo.rb'
#   define_gitlab_server('mygitlab', 'https://mygitlab.com')
#   define_gitea_server('mygitea', 'https://mygitea.com')
#   # Now you may use your own server instance in projects.yml like so:
#   # mygitlab:
#   #   orgname:
#   #     projectname:
#   #       language: rust
#   #     ruby_project:
#   #       language ruby
# end