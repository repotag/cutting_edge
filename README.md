# CuttingEdge -- Simple, self-hosted dependency monitoring

[![Build Status](https://travis-ci.org/repotag/cutting_edge.svg?branch=master)](https://travis-ci.org/repotag/cutting_edge)
[![Coverage Status](https://coveralls.io/repos/github/repotag/cutting_edge/badge.svg?branch=master)](https://coveralls.io/github/repotag/cutting_edge?branch=master)
[![Cutting Edge Dependency Status](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/svg 'Cutting Edge Dependency Status')](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/info)

CuttingEdge monitors the status of the dependencies of your projects and lets you know when any of them go out of date. It:

* Generates badge images that you can include in your projects' Readme, like the one above!
* Can send you email when the status of a project's dependencies changes
* Serves a simple [info page](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/info) detailing the status of each project
* Supports the following languages:
  * Ruby
  * Python
  * Rust
  * [more can be added]()
* Supports the following platforms:
  * GitHub
  * Gitlab (both gitlab.com and self-hosted instances)
  * Gitea (self-hosted)
  * Both public and [private repositories](#Authorization-and-private-repositories)

Moreover, CuttingEdge is lightweight and easy to deploy: 

* No database required
* Simple configuration through a `projects.yml` file
* Requires relatively few resources (~120MB RAM), so..
* It can even run on Heroku's free plan!

By default, CuttingEdge refreshes the status of your projects' dependencies every hour, but this (and other such settings) can easily be configured in `config.rb`.

**View the web front end of a [live instance](https://dometto-cuttingedge.herokuapp.com/)**

## Installation

`gem install cutting_edge`

Or run from source:

```
git clone https://github.com/repotag/cutting_edge.git
cd cutting_edge
bundle install
bundle exec cutting_edge
```

Before running, define your repositories in [projects.yml](#projects-yml). You may also want to change some settings in [config.rb](#config-rb).

### Deploying on Heroku

CuttingEdge runs out of the box on Heroku, and is lightweight enough to function on the Heroku free plan. We recommend you:

1. Clone/fork [this](ADD URL TO HEROKU EXAMPLE) repository, as it already contains some `config.rb` settings relevant to Heroku
2. Edit `projects.yml` and commit it to the repo
3. `heroku create my-cuttingedge`
4. `git push heroku master`

You may also want to set some [Heroku config variables](https://devcenter.heroku.com/articles/config-vars), for instance to [use authentication tokens](#Authorization-and-private-repositories) in `config.rb`.

## Usage

When your instance of CuttingEdge is running, you can visit the landing page by pointing your browser to the root URL of the app. Locally, it is by default accessible at:

`http://localhost:4567/`

(Of course, you can also bind it to port 80 or 443 and make it accessible from the internet using the `--port` and `--host` arguments. Or you could place Apache or nginx in front of CuttingEdge.)

An instance on Heroku will be accessible through:

`https://your-app-name.herokuapp.com/`

### projects.yml

Explain language, locations key.

### config.rb

### Email Notifications

### Defining your own git repository server

You can monitor projects on your own, self-hosted Gitlab or Gitea instances. To do so, you need to tell CuttingEdge about your server by editing `config.rb` as follows:

```ruby
module CuttingEdge
    require './lib/cutting_edge/repo.rb'
    define_gitlab_server('mygitlab', 'https://mygitlab.com')
    define_gitea_server('mygitea', 'https://mygitea.com')
end
```

This will allow you to use the `mygitlab:` and `mygitea:` keys in `projects.yml`, for instance like so:

```yaml
github:
   repotag:
     cutting_edge:
       lang: ruby
mygitlab:
  myorg:
    project-name:
      lang: rust
mygitea:
  myorg2:
    project-name2:
      lang: python
```

Don't forget to run CuttingEdge with the `--config` option!

### Authorization and private repositories

If you want to monitor dependencies in a private (e.g. GitHub or Gitlab) project, you can instruct CuttingEdge to use an API token for accessing the dependency files. In `projects.yml`:

```yaml
github:
   secret-org:
     secret-repo:
       auth_token: 'mysecrettoken'
```

For info on generating API tokens, see:

* [GitHub](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)
* [GitLab](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
* [Gitea](https://docs.gitea.io/en-us/api-usage/)

If you don't want to expose your API token in `project.yml` (**which you shouldn't** when it is publicly accessible on the internet), you can instead define your project repository programatically in `config.rb`. This will allow you to set secrets (auth_token, but if desired also name and org of the repository) by (for instance) utilising environment variables:

```ruby
module CuttingEdge
    require './lib/cutting_edge/repo.rb'
    REPOSITORIES = {
      "gitlab/#{ENV['SECRET_REPO1_ORG']}/#{ENV['SECRET_REPO1_NAME']}" => GitlabRepository.new(org: ENV['SECRET_REPO1_ORG'], name: ENV['SECRET_REPO1_NAME'], auth_token: ENV['SECRET_REPO1_TOKEN'], hide: true)
    }
end
```

Setting the `hide` key to true will ensure your private repo is not listed in the web frontend, unless you enter your CuttingEdge secret token on the landing page.

This approach is especially useful on Heroku, where you can use [Heroku config variables](https://devcenter.heroku.com/articles/config-vars).

# Refreshing dependency status through git hooks

CuttingEdge by default checks whether the status of your dependencies has changed once every hour. However, if you wish, you can also setup hooks so that dependency status is checked (for instance) whenever you make a commit to your project.

For this purpose, CuttingEdge provides the following route:

```
http://mycuttingedge.com/github/org/myproject/refresh?token=mysecrettoken
```

An HTTP `POST` request to that route will cause the dependencies for that project to refresh. This requires you to define a secret token in `config.rb`, so that third parties cannot trigger refreshes. In `config.rb`:

```ruby
module CuttingEdge
  CuttingEdge::SECRET_TOKEN = 'mysecrettoken' # Note: this token is used to refresh all the projects on your CuttingEdge instance
end
```

Using this route you can, for instance, set up a [GitHub Action](https://docs.github.com/en/free-pro-team@latest/actions) (or equivalent for other providers). Of course, this requires defining the secret token as (for instance) a [GitHub Secret](https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets).

You can test the route like this:

```
curl -d 'token=mysecrettoken' http://mycuttingedge.com/github/org/myproject/refresh
```

## Contributing

## License

This work is licensed under the terms of the [GNU GPLv3.0](LICENSE).
