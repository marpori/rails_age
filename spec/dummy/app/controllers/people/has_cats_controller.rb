class People::HasCatsController < ApplicationController
  before_action :set_people_has_cat, only: %i[show edit update destroy]

  def index
    @people_has_cats = People::HasCat.all
  end

  def show
  end

  def new
    @people_has_cat = People::HasCat.new
  end

  def edit
  end

  def create
    @people_has_cat = People::HasCat.new(people_has_cat_params)

    if @people_has_cat.save
      redirect_to @people_has_cat, notice: 'Has cat was successfully created.'
    else
      render :new
    end
  end

  def update
    if @people_has_cat.update(people_has_cat_params)
      redirect_to @people_has_cat, notice: 'Has cat was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @people_has_cat.destroy
    redirect_to people_has_cats_url, notice: 'Has cat was successfully destroyed.'
  end

  private

  def set_people_has_cat
    @people_has_cat = People::HasCat.find(params[:id])
  end

  def people_has_cat_params
    params.require(:people_has_cat).permit(:role, :start_id, :end_id)
  end
end
