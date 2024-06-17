class Animals::CatsController < ApplicationController
  before_action :set_animals_cat, only: %i[show edit update destroy]

  def index
    @animals_cats = Animals::Cat.all
  end

  def show
  end

  def new
    @animals_cat = Animals::Cat.new
  end

  def edit
  end

  def create
    @animals_cat = Animals::Cat.new(animals_cat_params)

    if @animals_cat.save
      redirect_to @animals_cat, notice: 'Cat was successfully created.'
    else
      render :new
    end
  end

  def update
    if @animals_cat.update(animals_cat_params)
      redirect_to @animals_cat, notice: 'Cat was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @animals_cat.destroy
    redirect_to animals_cats_url, notice: 'Cat was successfully destroyed.'
  end

  private

  def set_animals_cat
    @animals_cat = Animals::Cat.find(params[:id])
  end

  def animals_cat_params
    params.require(:animals_cat).permit(:name)
  end
end
