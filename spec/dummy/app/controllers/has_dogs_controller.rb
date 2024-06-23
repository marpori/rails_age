class HasDogsController < ApplicationController
  before_action :set_has_dog, only: %i[show edit update destroy]

  def index
    @has_dogs = HasDog.all
  end

  def show
  end

  def new
    @has_dog = HasDog.new
  end

  def edit
  end

  def create
    @has_dog = HasDog.new(has_dog_params)

    if @has_dog.save
      redirect_to @has_dog, notice: 'Has dog was successfully created.'
    else
      render :new
    end
  end

  def update
    if @has_dog.update(has_dog_params)
      redirect_to @has_dog, notice: 'Has dog was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @has_dog.destroy
    redirect_to has_dogs_url, notice: 'Has dog was successfully destroyed.'
  end

  private

  def set_has_dog
    @has_dog = HasDog.find(params[:id])
  end

  def has_dog_params
    params.require(:has_dog).permit(:role, :start_id, :end_id)
  end
end
