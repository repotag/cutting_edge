# rubydeps

```
$ bundle exec ruby test.rb 
First trying with Gem::SpecFetcher
Checking dependencies status for rake
Current required version of rake: < 14.0, >= 10.0
Latest version of rake: 13.0.1
So is the rake requirement outdated? true

Checking dependencies status for gollum
Current required version of gollum: < 4.0, >= 2.0
Latest version of gollum: 4.1.4
So is the gollum requirement outdated? false

Benchmark with Gem::SpecFetcher
Rehearsal ----------------------------------------------
             0.000000   0.000000   0.000000 (  0.001200)
------------------------------------- total: 0.000000sec

                 user     system      total        real
             0.000000   0.000000   0.000000 (  0.000706)

Now trying with rubygems API
Checking dependencies status for rake
Current required version of rake: < 14.0, >= 10.0
Latest version of rake: 13.0.1
So is the rake requirement outdated? true

Checking dependencies status for gollum
Current required version of gollum: < 4.0, >= 2.0
Latest version of gollum: 4.1.4
So is the gollum requirement outdated? false

Benchmark with rubygems API 
Rehearsal ----------------------------------------------
             0.010000   0.000000   0.010000 (  1.126841)
------------------------------------- total: 0.010000sec

                 user     system      total        real
             0.000000   0.000000   0.000000 (  0.672203)
```
