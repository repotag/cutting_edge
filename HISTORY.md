# 0.3 / 2022-10-15

* Added the `--redis` command line argument.
* Added Docker support.
* Use Redis on Heroku by default to avoid flakiness caused by Heroku's dynos.
* Change default branch name to `main`
* Do not mail when the diff is empty.
# v0.2.1 / 2021-09-02

* Add ~= comparator and translate it to ~>. Resolves #66 (@bartkamphorst)