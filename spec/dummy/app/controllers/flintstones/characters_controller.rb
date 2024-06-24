class Flintstones::CharactersController < ApplicationController
  before_action :set_flintstones_character, only: %i[show edit update destroy]

  def index
    @flintstones_characters = Flintstones::Character.all
  end

  def show
  end

  def new
    @flintstones_character = Flintstones::Character.new
  end

  def edit
  end

  def create
    @flintstones_character = Flintstones::Character.new(flintstones_character_params)

    if @flintstones_character.save
      redirect_to @flintstones_character, notice: 'Character was successfully created.'
    else
      render :new
    end
  end

  def update
    if @flintstones_character.update(flintstones_character_params)
      redirect_to @flintstones_character, notice: 'Character was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @flintstones_character.destroy
    redirect_to flintstones_characters_url, notice: 'Character was successfully destroyed.'
  end

  private

  def set_flintstones_character
    @flintstones_character = Flintstones::Character.find(params[:id])
  end

  def flintstones_character_params
    params.require(:flintstones_character).permit(:name)
  end
end
