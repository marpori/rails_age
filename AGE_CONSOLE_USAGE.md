# AGE USAGE within Rails Console

```ruby
bin/rails c

fred = Person.new(first_name: 'Fredrick Jay', last_name: 'Flintstone')
fred.valid?
fred.save
fred.to_h # should have an ID

# fails because of a missing required field (Property)
incomplete = Person.new(first_name: 'Fredrick Jay')
incomplete.valid?
incomplete.errors
incomplete.to_h

# fails because of uniqueness constraints
jay = Person.create(first_name: 'Fredrick Jay', last_name: 'Flintstone')
jay.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}
jay.valid?
=> false
jay.errors
=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=base, type=record not unique, options={}>, #<ActiveModel::Error attribute=first_name, type=property combination not unique, options={}>, #<ActiveModel::Error attribute=last_name, type=property combination not unique, options={}>]>
irb(main):008> jav.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}

# .create is a shortcut for .new and .save
quarry = Company.create(company_name: 'Bedrock Quarry')
quarry.to_h # should have an ID

# create an edge (no generator yet)
job = HasJob.create(start_node: fred, end_node: quarry, employee_role: 'Crane Operator')
job.to_h # should have an ID
```
