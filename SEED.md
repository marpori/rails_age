# Sample Seed File for sample Flintstones App

```ruby
# db/seed.rb
# Sample Seed File for sample Flintstones App
# USAGE: rails db:seed
#
# Data from:
# https://www.reddit.com/r/UsefulCharts/comments/ugip6x/the_flintstones_family_tree/#lightbox

# Great Great Grandparents generation
#####################################
zeke = Person.create(name: 'Zeke Flintstone', gender: 'female')
jed = Person.create(name: 'Jed Flintstone', gender: 'male')
#spouse of
HasSpouse.create(role: 'wife', start_node: zeke, end_node: jed)
HasSpouse.create(role: 'husband', start_node: jed, end_node: zeke)

# Great Grandparents generation
###############################
rock = Person.create(name: 'Rockbottom Flintstone', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: zeke, end_node: rock)
HasChild.create(role: 'father', start_node: jed, end_node: rock)

mr_slate = Person.create(name: 'Mr. Slate', gender: 'male')
mrs_slate = Person.create(name: 'Mrs. Slate', gender: 'female')
#spouse of
HasSpouse.create(role: 'wife', start_node: mrs_slate, end_node: mr_slate)
HasSpouse.create(role: 'husband', start_node: mr_slate, end_node: mrs_slate)


# Grandparents generation
#########################
ed = Person.create(name: 'Ed Flintstone', gender: 'male')
# child of
HasChild.create(role: 'father', start_node: rock, end_node: ed)

giggles = Person.create(name: 'Giggles Flintstone', gender: 'male')
# child of
HasChild.create(role: 'father', start_node: rock, end_node: giggles)

# siblings
HasSibling.create(role: 'brother', start_node: giggles, end_node: ed)
HasSibling.create(role: 'brother', start_node: ed, end_node: giggles)

edna = Person.create(name: 'Edna Hardrock Flintstone', gender: 'female')
HasSpouse.create(role: 'wife', start_node: edna, end_node: ed)
HasSpouse.create(role: 'husband', start_node: ed, end_node: edna)

tex = Person.create(name: 'Tex Hardrock', gender: 'male')
# siblings
HasSibling.create(role: 'sister', start_node: edna, end_node: tex)
HasSibling.create(role: 'brother', start_node: tex, end_node: edna)

perl = Person.create(name: 'Pearl Slaghoople', gender: 'female')
rich = Person.create(name: 'Richard Slaghoople', gender: 'male')
#spouse of
HasSpouse.create(role: 'wife', start_node: perl, end_node: rich)
HasSpouse.create(role: 'husband', start_node: rich, end_node: perl)

bob = Person.create(name: 'Bob Rubble', gender: 'male')
flo = Person.create(name: 'Flo Slate Rubble', gender: 'female')
#spouse of
HasSpouse.create(role: 'wife', start_node: flo, end_node: bob)
HasSpouse.create(role: 'husband', start_node: bob, end_node: flo)
# child of
HasChild.create(role: 'mother', start_node: mrs_slate, end_node: flo)
HasChild.create(role: 'father', start_node: mr_slate, end_node: flo)

jean = Person.create(name: 'Jean McBricker', gender: 'female')
brick = Person.create(name: 'Brick McBricker', gender: 'male')
#spouse of
HasSpouse.create(role: 'wife', start_node: jean, end_node: brick)
HasSpouse.create(role: 'husband', start_node: brick, end_node: jean)

mary_lou = Person.create(name: 'Mary Lou Hardrock', gender: 'female')
tumbleweed = Person.create(name: 'Tumbleweed Hardrock', gender: 'male')
# child of
HasChild.create(role: 'father', start_node: tex, end_node: tumbleweed)
HasChild.create(role: 'father', start_node: tex, end_node: mary_lou)
# siblings of
HasSibling.create(role: 'sister', start_node: mary_lou, end_node: tumbleweed)
HasSibling.create(role: 'brother', start_node: tumbleweed, end_node: mary_lou)

# Stars generation
###################
fred = Person.create(name: 'Fred Flintstone', gender: 'male')
# child of
HasChild.create(role: 'father', start_node: ed, end_node: fred)
HasChild.create(role: 'mother', start_node: edna, end_node: fred)

wilma = Person.create(name: 'Wilma Slaghoople Flintstone', gender: 'female')
# child of
HasChild.create(role: 'mother', start_node: perl, end_node: wilma)
HasChild.create(role: 'father', start_node: rich, end_node: wilma)

#spouse of
HasSpouse.create(role: 'wife', start_node: wilma, end_node: fred)
HasSpouse.create(role: 'husband', start_node: fred, end_node: wilma)

barney = Person.create(name: 'Barney Rubble', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: flo, end_node: barney)
HasChild.create(role: 'father', start_node: bob, end_node: barney)

betty = Person.create(name: 'Betty McBricker Rubble', gender: 'female')
# has child
HasChild.create(role: 'mother', start_node: jean, end_node: betty)
HasChild.create(role: 'father', start_node: brick, end_node: betty)
# spause of
HasSpouse.create(role: 'wife', start_node: betty, end_node: barney)
HasSpouse.create(role: 'husband', start_node: barney, end_node: betty)

dusty = Person.create(name: 'Dusty Rubble', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: flo, end_node: dusty)
HasChild.create(role: 'father', start_node: bob, end_node: dusty)

# siblings
HasSibling.create(role: 'brother', start_node: barney, end_node: dusty)
HasSibling.create(role: 'brother', start_node: dusty, end_node: barney)

brad = Person.create(name: 'Brad McBricker', gender: 'male')
# has child
HasChild.create(role: 'mother', start_node: jean, end_node: brad)
HasChild.create(role: 'father', start_node: brick, end_node: brad)

#siblings
HasSibling.create(role: 'sister', start_node: betty, end_node: brad)
HasSibling.create(role: 'brother', start_node: brad, end_node: betty)

jerry = Person.create(name: 'Jerry Slaghoople', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: perl, end_node: jerry)
HasChild.create(role: 'father', start_node: rich, end_node: jerry)
# siblings
HasSibling.create(role: 'sister', start_node: wilma, end_node: jerry)
HasSibling.create(role: 'brother', start_node: jerry, end_node: wilma)

micky = Person.create(name: 'Mickey Slaghoople', gender: 'female')
# child of
HasChild.create(role: 'mother', start_node: perl, end_node: micky)
HasChild.create(role: 'father', start_node: rich, end_node: micky)
# siblings
HasSibling.create(role: 'sister', start_node: micky, end_node: wilma)
HasSibling.create(role: 'sister', start_node: micky, end_node: jerry)
HasSibling.create(role: 'sister', start_node: wilma, end_node: micky)
HasSibling.create(role: 'brother', start_node: jerry, end_node: micky)

mica = Person.create(name: 'Mica Slaghoople', gender: 'female')
# child of
HasChild.create(role: 'mother', start_node: perl, end_node: mica)
HasChild.create(role: 'father', start_node: rich, end_node: mica)
# siblings
HasSibling.create(role: 'sister', start_node: mica, end_node: wilma)
HasSibling.create(role: 'sister', start_node: mica, end_node: micky)
HasSibling.create(role: 'sister', start_node: mica, end_node: jerry)
HasSibling.create(role: 'sister', start_node: wilma, end_node: mica)
HasSibling.create(role: 'sister', start_node: micky, end_node: mica)
HasSibling.create(role: 'brother', start_node: jerry, end_node: mica)

# current generation
####################
stoney = Person.create(name: 'Stoney Flintstone', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: wilma, end_node: stoney)
HasChild.create(role: 'father', start_node: fred, end_node: stoney)

pebbles = Person.create(name: 'Pebbles Flintstone', gender: 'female')
# child of
HasChild.create(role: 'mother', start_node: wilma, end_node: pebbles)
HasChild.create(role: 'father', start_node: fred, end_node: pebbles)

# siblings
HasSibling.create(role: 'sister', start_node: pebbles, end_node: stoney)
HasSibling.create(role: 'brother', start_node: stoney, end_node: pebbles)

bamm_bamm = Person.create(name: 'Bamm-Bamm Rubble', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: betty, end_node: bamm_bamm)
HasChild.create(role: 'father', start_node: barney, end_node: bamm_bamm)

#spouse of
HasSpouse.create(role: 'wife', start_node: pebbles, end_node: bamm_bamm)
HasSpouse.create(role: 'husband', start_node: bamm_bamm, end_node: pebbles)


# newest Generation
####################
roxie = Person.create(name: 'Roxie Rubble', gender: 'female')
# child of
HasChild.create(role: 'mother', start_node: pebbles, end_node: roxie)
HasChild.create(role: 'father', start_node: bamm_bamm, end_node: roxie)

chip = Person.create(name: 'Chip Rubble', gender: 'male')
# child of
HasChild.create(role: 'mother', start_node: pebbles, end_node: chip)
HasChild.create(role: 'father', start_node: bamm_bamm, end_node: chip)

# siblings
HasSibling.create(role: 'sister', start_node: roxie, end_node: chip)
HasSibling.create(role: 'brother', start_node: chip, end_node: roxie)
```
