# How to Deploy CuttingEdge on Heroku

**Note: on Heroku, CuttingEdge uses `heroku.config.rb` instead of `config.rb`**.

**Note: if you will be using a public GitHub or GitLab repo to host your CuttingEdge configuration, make sure not to put any secrets in `heroku.config.rb` or `projects.yaml`.** Instead, use [environment variables](https://render.com/docs/environment-variables) (for instance to [set authentication tokens](https://github.com/repotag/cutting_edge/blob/main/README.md#Authorization-and-private-repositories)).

Steps:

1. Fork and clone this repository locally
1. Move `Procfile` from the `heroku` subdirectory into the repository root and commit.
1. Move the sample `heroku.config.rb` from the `heroku` subdirectory into the repository.
1. Edit `heroku.config.rb` to suit your needs and commit.
1. Edit `projects.yml` to suit your needs and commit it to the repo.
1. `gem install bundler && bundle install`
2. `git add Gemfile.lock && git commit -m "Commit Gemfile.lock for use on Heroku"
3. `heroku create my-cuttingedge`
4. `heroku config:add HEROKU_APP_NAME=my-cuttingedge`
5. `heroku addons:create heroku-redis:hobby-dev -a my-cuttingedge` (using Redis is highly recommended on Heroku)
6. `git push heroku master`
7. *Optional, if you want to receive [email notifications](#Email-Notifications)*:
  * `heroku addons:create mailgun:starter`
  * `heroku config:add CUTTING_EDGE_MAIL_TO=mydependencies@mydependencymonitoring.com`

You may also want to set some [Heroku config variables](https://devcenter.heroku.com/articles/config-vars), for instance to [use authentication tokens](#Authorization-and-private-repositories) in `heroku.config.rb`.