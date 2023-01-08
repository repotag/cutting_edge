# CuttingEdge -- Simple, self-hosted dependency monitoring

[![Ruby Build](https://github.com/repotag/cutting_edge/actions/workflows/test.yaml/badge.svg)](https://github.com/repotag/cutting_edge/actions/workflows/test.yaml)
[![Coverage Status](https://coveralls.io/repos/github/repotag/cutting_edge/badge.svg?branch=main)](https://coveralls.io/github/repotag/cutting_edge?branch=main)
[![Cutting Edge Dependency Status](https://cuttingedge.onrender.com/github/repotag/cutting_edge/svg 'Cutting Edge Dependency Status')](https://cuttingedge.onrender.com/github/repotag/cutting_edge/info)
[![Docker Pulls](https://img.shields.io/docker/pulls/dometto/cuttingedge)](https://hub.docker.com/r/dometto/cuttingedge)

CuttingEdge monitors the status of the dependencies of your projects and lets you know when any of them go out of date.

**View the web front end of a [live instance](https://cuttingedge.onrender.com/)**.

## Features

* Generates badge images that you can include in your projects' Readme, like the one above!
* Can send you email when the status of a project's dependencies changes
* Serves a simple [info page](https://cuttingedge.onrender.com/github/repotag/cutting_edge/info) detailing the status of each project
* Supports the following languages:
  * Ruby
  * Python
  * Rust
  * [...add more!](https://github.com/repotag/cutting_edge/wiki/Languages)
* Supports the following platforms:
  * GitHub
  * Gitlab (both gitlab.com and [self-hosted instances](#Adding-self-hosted-repository-servers))
  * Gitea ([self-hosted](#Adding-self-hosted-repository-servers))
  * Both public and [private repositories](#Authorization-and-private-repositories)

CuttingEdge is lightweight and easy to deploy:

* No database required
  * but you can optionally use [data stores like Redis](#Using-Redis-and-other-data-stores)
* Simple configuration through a `projects.yml` file
* Requires relatively few resources (~120MB RAM), so...
* It can even run on many hosting services' free plans, such as [Render.com](https://render.com)
  * Easily deploy to Render.com with the provided [configuration](#Deploying-on-Render)!

## Installation

### Using Docker

To run CuttingEdge on port 4567 on the host machine, with config.rb and projects.yml in the current working directory, simply:

* `docker pull dometto/cuttingedge:main`
* `docker run -d --rm -p 4567:4567 -v $(pwd):/cutting_edge dometto/cuttingedge:main -c config.r`

(Instead of using `main`, you can also use a release tag, e.g. `dometto/cuttingedge:v0.2.1`.)

Before running, define your repositories in [projects.yml](#projectsyml). You may also want to change some settings in [config.rb](#configrb).

Also see our example [docker-compose](docker-compose.yml) file for an example of how to use CuttingEdge with [Redis as a datastore](#Using-Redis-and-other-data-stores) via Docker.

### Deploying on Render

CuttingEdge runs out of the box on Render.com, and is lightweight enough to function on the free plan. This repository already contains the `render.yaml` needed for deployment.

**Note: on Render, CuttingEdge uses `render.config.rb` instead of `config.rb`**.

**Note: if you will be using a public GitHub or GitLab repo to host your CuttingEdge configuration, make sure not to put any secrets in `render.config.rb` or `projects.yaml`.**. Instead, use [environment variables](https://render.com/docs/environment-variables) (for instance to [set authentication tokens](#Authorization-and-private-repositories)). **You can also add `render.config.rb` and `projects.yaml` as "secret files" on the Render.com Dashboard instead of committing them to your repo!**

Steps:

1. Fork this repository (for use on Render.com, your fork needs to be available on GitHub or GitLab).
1. Clone your fork locally.
1. Edit your `render.yaml` (set a name for your instance) and commit it to the repo.
1. Edit your `projects.yml` to suit your needs and commit it to the repo (or add it as a secret file).
1. Edit your `render.config.rb` to suit your needs and commit it to the repo (or add it as a secret file).
1. `gem install bundler && bundle install`
1. `git add Gemfile.lock && bundle lock --add-platform x86_64-linux && git commit -m "Commit Gemfile.lock for use on Render"
1. On Render.com, create a new Blueprint instance:
  * On the Render Dashboard, go to the Blueprint page and click the New Blueprint Instance button.
  * Connect your forked repository.
1. Render.com will now deploy your instance of CuttingEdge!
  * Re-deployment will be triggered whenever you push to your GitHub or GitLab repo, or whenver you update the environment variables or secret files on the Render.com Dashboard.

Note that Render switches off apps running on their free plan when they idle, so you may want to ensure your app does not idle by polling it periodically, or upgrade to a higher plan.

### Deploying on Heroku

Heroku's free plan has been discontinued, but this Repository still contains the necessary `Procfile` and `heroku.config.rb` for hosting CuttingEdge on Heroku. See [here](https://github.com/repotag/cutting_edge/blob/main/heroku/HEROKU_HOWTO.md) for instructions.

### As a gem

Simply:

```
$ gem install cutting_edge
$ cutting_edge
```

Or run from source:

```
$ git clone https://github.com/repotag/cutting_edge.git
$ cd cutting_edge
$ bundle install
$ bundle exec cutting_edge
```

Before running, define your repositories in [projects.yml](#projectsyml). You may also want to change some settings in [config.rb](#configrb).

## Usage

When your instance of CuttingEdge is running, you can visit the landing page by pointing your browser to the root URL of the app. Locally, it is by default accessible at:

`http://localhost:4567/`

(Of course, you can also bind it to port 80 or 443 and make it accessible from the internet using the `--port` and `--host` arguments. Or you could place Apache or nginx in front of CuttingEdge.)

An instance on Heroku will be accessible through:

`https://your-app-name.herokuapp.com/`

### projects.yml

`projects.yml` is the file in which you define which repositories you want CuttingEdge to monitor. Here's an example:

```yaml
github:
  my_org:
    my_project:
      language: ruby
```

This will make CuttingEdge monitor the GitHub project `my_org/my_project`. You can add multiple repositories under the `github:` key, and also use the `gitlab:` key for repositories on gitlab.com out of the box. If you [add self-hosted providers](#Adding-self-hosted-repository-servers), you'll be able to define repositories using, for instance, `my_gitea:`.

 The `language:` key can currently be set to `ruby` (default), `rust`, or `python`. Further supported keys:

* `auth_token`: see [here](#Authorization-and-private-repositories)
* `hide`: see [here](#Hide-repositories)
* `locations`: use to change the default path to dependency definition files. For instance, for a Ruby project, CuttingEdge will by default try to monitor `Gemfile` and `my_project.gemspec`. You can override this with `language: [Gemfile, alternative/file.gemspec]`
* `branch`: use a different branch than the default `main`
* `email`:
  * disable email notifications for a single project by setting this to `false`
  * use a non-default address delivery address for this project by setting this to e.g. `myproject@mydependencymonitoring.com`

Note: by default CuttingEdge will use `projects.yml` in the working directory. You may optionally specify a different path by running `cutting_edge path/to/my_projects.yml`.

Instead of `projects.yml`, you can also [define projects in `config.rb`](#Defining-repositories-in-configrb).

### config.rb

To configure CuttingEdge specific settings in `config.rb`, you can run `cutting_edge` with the `--config` switch (you can optionally specify an alternative location for the config file). Always make sure you are defining your settings from within the `CuttingEdge` module. For instance:

```ruby
module CuttingEdge
  REFRESH_SCHEDULE = '2h'
end
```

The sample [config.rb](config.rb) contains some examples of constants that you may wish to configure. Here are some descriptions of what the less obvious ones achieve:

* `SECRET_TOKEN`: set a global secret token for administrative purposes. This token is used to configure [hooks](#Refreshing-dependency-status-through-git-hooks), and to list [hidden projects](#Hide-Repositories).
* `SERVER_URL`: the link to the app that should be displayed, for instance in emails. Defaults to `"http://#{SERVER_HOST}"`
* `MAIL_TEMPLATE`: override the [ERB](https://www.stuartellis.name/articles/erb/) template used to render [emails](#Email-Notifications). See [mail.html.erb](lib/cutting_edge/templates/mail.html.erb) for an example on which variables you can use within the template.

### Email Notifications

CuttingEdge can send email notifications whenever a change in the dependency status of a monitored project is detected. This is disabled by default. Enable it in `config.rb`:

```ruby
module CuttingEdge
  MAIL_TO = 'mydeps@mymail.com'  # Default address to send email to. If set to false (=default!), don't send any emails except for repositories that have their 'email:' attribute set in projects.yml
  MAIL_FROM = "cutting_edge@my_server.com" # From Address used for sending emails.
end
```

By default, the app wil try to use an SMTP server on `localhost:25`. Change these settings in your `config.rb` by calling `Mail.defaults`:

```ruby
# This should be outside the module CuttingEdge
Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 1025
end
```

See [the mail gem](https://github.com/mikel/mail#sending-an-email) for more information.

You can switch off email notifications for a single project by setting its `email:` key to `false` in [projects.yml](#projectsyml). Alternatively, you can set the `email:` key for a single project to a different address than the default `MAIL_TO`.

### Adding self-hosted repository servers

You can monitor projects on your own self-hosted Gitlab or Gitea instances. To do so, you need to tell CuttingEdge about your server by editing `config.rb` as follows:

```ruby
module CuttingEdge
    require './lib/cutting_edge/repo.rb'
    define_gitlab_server('mygitlab', 'https://mygitlab.com')
    define_gitea_server('mygitea', 'https://mygitea.com')
end
```

This will allow you to use the `mygitlab:` and `mygitea:` keys in `projects.yml`, for instance like so:

```yaml
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
* [Gitlab](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
* [Gitea](https://docs.gitea.io/en-us/api-usage/)

### Defining repositories in config.rb

If you don't want to expose information about a project in (**such as an [API token](#Authorization-and-private-repositories)!**) `projects.yml` (which may be publically accessible on the internet), you can instead define your project repository programatically in `config.rb`. This will allow you to define repositories with secret parameters by (for instance) utilising environment variables:

```ruby
module CuttingEdge
    require './lib/cutting_edge/repo.rb'
    REPOSITORIES = {
      "gitlab/#{ENV['SECRET_REPO1_ORG']}/#{ENV['SECRET_REPO1_NAME']}" => GitlabRepository.new(org: ENV['SECRET_REPO1_ORG'], name: ENV['SECRET_REPO1_NAME'], auth_token: ENV['SECRET_REPO1_AUTH_TOKEN'], hide: ENV['SECRET_REPO1_HIDE_TOKEN'], email: 'myemail@mydomain.org')
    }
end
```

This approach is especially useful on Heroku, where you can use [Heroku config variables](https://devcenter.heroku.com/articles/config-vars).

**NB: When adding repositories in config.rb, you must explicitly set the email attribute (or else email will be considered disabled for the repo).**

### Hide Repositories

You may want the name and dependency monitoring information for private repositories (see above) not to be visible on the internet. To achieve this, you can use `hide: token` in `projects.yml`:

```yaml
github:
   secret-org:
     secret-repo:
       auth_token: 'mysecrettoken'
       hide: 'myhiddenrepo'
```

...or again, you can do so in `config.rb` following the [method explained above](#Defining-repositories-in-configrb):

```ruby
GitlabRepository.new(org: ENV['SECRET_REPO1_ORG'], name: ENV['SECRET_REPO1_NAME'], auth_token: ENV['SECRET_REPO1_AUTH_TOKEN'], hide: ENV['SECRET_REPO1_HIDE_TOKEN'])
end
```

Setting the `hide` key to a token of your choice will ensure that:

1. your hidden repo is not listed in the web frontend.
  * to list all hidden repositories, you can enter your `CuttingEdge::SECRET_TOKEN` after clicking the "List hidden repositories" on the landing page.
  * **NB: this is your [global administrator token](#configrb), not the particular token used to hide a particular project.** 
2. the `/info` route and SVG image for your hidden repo are not accessible without the repo-specific token you have set via `hide:`

When you go to the `/info` route for your hidden repo (by first entering your administrator token, then clicking on the SVG for the project), you can click the "Embed" button and thereby acquire a link to the SVG dependency status image that contains the `hide:` token. You can thus use this link on a private repository, without giving collaborators on that project access to information about your other hidden repositories!

### Refreshing dependency status through git hooks

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

## Using Redis and other data stores

CuttingEdge does not require persistence, as the data it uses (which dependencies does a project have, and are they up to date?) is refreshed periodically anyway. By default, this information is stored in memory. However, if you would like to store data in a different kind of data store (for instance Redis) that can be trivially accomplished. This may further decrease the amount of RAM CuttingEdge requires, and possibly improve performance.

CuttingEdge uses [Moneta](https://github.com/moneta-rb/moneta) as an abstraction layer for its data store, so to change the data store can just do the following in `config.rb`:

```ruby
module CuttingEdge
  STORE = Moneta.new(:Redis)
end
```

See the [Moneta](https://github.com/moneta-rb/moneta) instructions.

Note that Heroku offers a free [Redis Add-on](https://elements.heroku.com/addons/heroku-redis).

## Contributing

See [here](CONTRIBUTING.md).

## License

This work is licensed under the terms of the [GNU Affero GPLv3.0](LICENSE). Copyright Dawa Ometto and Bart Kamphorst, 2020.
