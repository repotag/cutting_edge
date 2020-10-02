# CuttingEdge -- Simple, self-hosted dependency monitoring

[![Build Status](https://travis-ci.org/repotag/cutting_edge.svg?branch=master)](https://travis-ci.org/repotag/cutting_edge)
[![Coverage Status](https://coveralls.io/repos/github/repotag/cutting_edge/badge.svg?branch=master)](https://coveralls.io/github/repotag/cutting_edge?branch=master)
[![Cutting Edge Dependency Status](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/svg 'Cutting Edge Dependency Status')](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/info)

CuttingEdge monitors the status of the dependencies of your projects and lets you know when any of them go out of date. It:

* Generates badge images that you can include in your projects' Readme, like the one above!
* Can send you e-mail when the status of a project's dependencies changes
* Serves a simple [info page](https://dometto-cuttingedge.herokuapp.com/github/repotag/cutting_edge/info) detailing the status for each project
* Supports the following languages:
  * Ruby
  * Python
  * Rust
  * [more can be added]()
* Supports the following platforms:
  * GitHub
  * Gitlab (both gitlab.com and self-hosted instances)
  * Gitea (self-hosted)

Moreover, CuttingEdge is light weight and easy to deploy: 

* No database required
* Simple configuration through a `projects.yml` file
* Requires relatively few resources (~120MB RAM), so..
* It can even run on Heroku's free plan!

By default, CuttingEdge refreshes the status of your projects' dependencies every hour, but this (and other such settings) can easily be configured in `config.rb`.

**View the web front end of a [live instance](https://dometto-cuttingedge.herokuapp.com/).**

## Installation

When your instance of CuttingEdge is running, you can visit the landing page by pointing your browser to the root URL of the app. Locally, it is by default accessible at:

`http://localhost:4567/`

(Of course, you can also bind it to port 80 or 443 and make it accessible from the internet using the `--port` and `--host` arguments. Or you could place Apache or nginx in front of CuttingEdge.)

An instance on Heroku will be accessible through:

`https://your-app-name.herokuapp.com/`

### Deploying on Heroku

## Usage

### projects.yml

### config.rb

## Contributing

## License

This work is licensed under the terms of the [GNU GPLv3.0](LICENSE).
