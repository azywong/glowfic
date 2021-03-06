# frozen_string_literal: true
class GalleriesController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_gallery, only: [:destroy, :edit, :update]
  before_filter :setup_new_icons, only: [:add, :icon]
  before_filter :set_s3_url, only: [:add, :icon]

  def index
    if params[:user_id].present?
      unless @user = User.find_by_id(params[:user_id]) || current_user
        flash[:error] = 'User could not be found.'
        redirect_to root_path and return
      end
    else
      return if login_required
      @user = current_user
    end

    @page_title = if @user.id == current_user.try(:id)
                    "Your Galleries"
                  else
                    @user.username + "'s Galleries"
                  end
    use_javascript('galleries/index')
  end

  def new
    @page_title = 'New Gallery'
    @gallery = Gallery.new
  end

  def create
    @gallery = Gallery.new(params[:gallery])
    @gallery.user = current_user

    unless @gallery.save
      flash.now[:error] = "Your gallery could not be saved."
      @page_title = 'New Gallery'
      render :action => :new and return
    end

    flash[:success] = "Gallery saved successfully."
    redirect_to gallery_path(@gallery)
  end

  def add
  end

  def show
    if params[:id].to_s == '0' # avoids casting nils to 0
      if params[:user_id].present?
        @user = User.find_by_id(params[:user_id])
      else
        return if login_required
        @user = current_user
      end
      @page_title = 'Galleryless Icons'
      use_javascript('galleries/index')
      render :show and return
    end

    @gallery = Gallery.find_by_id(params[:id])
    unless @gallery
      flash[:error] = "Gallery could not be found."
      redirect_to galleries_path and return
    end

    @user = @gallery.user
    @page_title = @gallery.name + ' (Gallery)'
    use_javascript('galleries/index')
  end

  def edit
    @page_title = 'Edit Gallery: ' + @gallery.name
  end

  def update
    unless @gallery.update_attributes(params[:gallery])
      flash.now[:error] = {}
      flash.now[:error][:message] = "Gallery could not be saved."
      flash.now[:error][:array] = @gallery.errors.full_messages
      @page_title = 'Edit Gallery: ' + @gallery.name_was
      render action: :edit and return
    end

    flash[:success] = "Gallery saved."
    redirect_to edit_gallery_path(@gallery)
  end

  def icon
    if params[:image_ids].present?
      unless @gallery # gallery required for adding icons from other galleries
        flash[:error] = "Gallery could not be found."
        redirect_to galleries_path and return
      end

      icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
      icons = Icon.where(id: icon_ids)
      icons.each do |icon|
        next unless icon.user_id == current_user.id
        @gallery.icons << icon
      end
      flash[:success] = "Icons added to gallery successfully."
      redirect_to gallery_path(@gallery) and return
    end

    icons = (params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    if icons.empty?
      flash.now[:error] = "You have to enter something."
      render :action => :add and return
    end

    failed = false
    @icons = icons
    icons = []
    @icons.each_with_index do |icon, index|
      icon = Icon.new(icon.except('file'))
      icon.user = current_user
      unless icon.valid?
        @icons[index]['url'] = '' if icon.errors.messages[:url] && icon.errors.messages[:url].include?('has already been taken')
        flash.now[:error] ||= {}
        flash.now[:error][:array] ||= []
        flash.now[:error][:array] += icon.errors.full_messages.map{|m| "Icon "+(index+1).to_s+": "+m.downcase}
        failed = true and next
      end
      icons << icon
    end

    if failed
      flash.now[:error][:message] = "Your icons could not be saved."
      render :action => :add and return
    elsif icons.empty?
      @icons = []
      flash.now[:error] = "Your icons could not be saved."
      render :action => :add
    elsif icons.all?(&:save)
      flash[:success] = "Icons saved successfully."
      if @gallery
        icons.each do |icon| @gallery.icons << icon end
        redirect_to gallery_path(@gallery) and return
      end
      redirect_to gallery_path(id: 0)
    else
      flash.now[:error] = "Your icons could not be saved."
      render :action => :add
    end
  end

  def destroy
    @gallery.destroy
    flash[:success] = "Gallery deleted successfully."
    redirect_to galleries_path
  end

  private

  def find_gallery
    @gallery = Gallery.find_by_id(params[:id])

    unless @gallery
      flash[:error] = "Gallery could not be found."
      redirect_to galleries_path and return
    end

    unless @gallery.user_id == current_user.id
      flash[:error] = "That is not your gallery."
      redirect_to galleries_path and return
    end
  end

  def setup_new_icons
    if params[:type] == "existing"
      use_javascript('galleries/add_existing')
    else
      use_javascript('galleries/add_new')
    end
    @icons = []
    find_gallery if params[:id] != '0'
    @unassigned = current_user.galleryless_icons
    @page_title = "Add Icons"
    @page_title += ": " + @gallery.name unless @gallery.nil?
  end

  def set_s3_url
    return if params[:type] == "existing"

    if !Rails.env.production? && S3_BUCKET.nil?
      logger.error "S3_BUCKET does not exist; icon upload will FAIL."
      @s3_direct_post = Struct.new(:url, :fields).new('', nil)
      return
    end

    @s3_direct_post = S3_BUCKET.presigned_post(
      key: "users/#{current_user.id}/icons/#{SecureRandom.uuid}_${filename}",
      success_action_status: '201',
      acl: 'public-read',
      content_type_starts_with: 'image/',
      cache_control: 'public, max-age=31536000')
  end
end
