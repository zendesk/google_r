# 0.2.0
- add Ruby gems workflow
- make specs RSpec 3 style

# 0.1.8
+ [enhancement] Gracefuly handle cases where Event is lacking 'created' aor 'updated' field.

# 0.1.7
+ [enhancement] Send also empty 'date' field for Event's start and end fields, to be able to update all day events (see https://stackoverflow.com/a/35658479/815183)

# 0.1.6
+ [enhancement] do not output every request to STDOUT, but to logger instead (#2)
