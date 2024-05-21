# RailsAge

Simplify Apache Age usage within a Rails application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails_age"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install rails_age
```

## Contributing

Create an MR and tests and I will review it.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Usage

I suggest you creat a folder within app called `graphs` and under that create a folder called `nodes` and `edges`. This will help you keep your code organized.

A full sample app can be found [here](https://github.com/btihen-dev/rails_graphdb_age_app) the summary usage is described below.

### Nodes

```ruby
# app/graphs/nodes/company.rb
module Nodes
  class Company
    include ApacheAge::Vertex

    attribute :company_name, :string
    validates :company_name, presence: true
  end
end
```

```ruby
# app/graphs/nodes/person.rb
module Nodes
  class Person
    include ApacheAge::Vertex

    attribute :first_name, :string, default: nil
    attribute :last_name, :string, default: nil
    attribute :given_name, :string, default: nil
    attribute :nick_name, :string, default: nil
    attribute :gender, :string, default: nil

    validates :gender, :first_name, :last_name, :given_name, :nick_name,
              presence: true

    def initialize(**attributes)
      super
      # use unless present? since attributes when empty sets to "" by default
      self.nick_name = first_name unless nick_name.present?
      self.given_name = last_name unless given_name.present?
    end
  end
end
```

### Edges

```ruby
# app/graphs/edges/works_at.rb
module Edges
  class WorksAt
    include ApacheAge::Edge

    attribute :employee_role, :string
    validates :employee_role, presence: true
  end
end
```

### Rails Console Usage

```ruby
fred = Nodes::Person.create(first_name: 'Fredrick Jay', nick_name: 'Fred', last_name: 'Flintstone', gender: 'male')
fred.to_h

quarry = Nodes::Company.create(company_name: 'Bedrock Quarry')
quarry.to_h

job = Edges::WorksAt.create(start_node: fred, end_node: quarry, employee_role: 'Crane Operator')
job.to_h
```

### Controller Usage

```ruby
# app/controllers/people_controller.rb
class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  # GET /people or /people.json
  def index
    @people = Nodes::Person.all
  end

  # GET /people/1 or /people/1.json
  def show; end

  # GET /people/new
  def new
    @person = Nodes::Person.new
  end

  # GET /people/1/edit
  def edit; end

  # POST /people or /people.json
  def create
    @person = Nodes::Person.new(**person_params)
    respond_to do |format|
      if @person.save
        format.html { redirect_to person_url(@person), notice: 'Person was successfully created.' }
        format.json { render :show, status: :created, location: @person }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /people/1 or /people/1.json
  def update
    respond_to do |format|
      if @person.update(**person_params)
        format.html { redirect_to person_url(@person), notice: 'Person was successfully updated.' }
        format.json { render :show, status: :ok, location: @person }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1 or /people/1.json
  def destroy
    @person.destroy!

    respond_to do |format|
      format.html { redirect_to people_url, notice: 'Person was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Nodes::Person.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def person_params
    # params.fetch(:person, {})
    params.require(:nodes_person).permit(:first_name, :last_name, :nick_name, :given_name, :gender)
  end
end
```
