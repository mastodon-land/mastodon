# frozen_string_literal: true

module Admin
  class AccountsController < BaseController
    before_action :set_account, except: %i(index new create)

    def index
      @accounts = Account.alphabetic.page(params[:page])

      @accounts = @accounts.local                                                               if params[:local].present?
      @accounts = @accounts.remote                                                              if params[:remote].present?
      @accounts = @accounts.where(domain: params[:by_domain])                                   if params[:by_domain].present?
      @accounts = @accounts.where('LOWER(username) LIKE LOWER(?)', "%#{params[:by_username]}%") if params[:by_username].present?
      @accounts = @accounts.silenced                                                            if params[:silenced].present?
      @accounts = @accounts.recent                                                              if params[:recent].present?
      @accounts = @accounts.suspended                                                           if params[:suspended].present?
    end

    def show; end

    def new
      @user = User.new.tap(&:build_account)
    end

    def create
      @user = User.new(user_params)
      # We generate random password, so user need to choose password (Forgot your password?) after validation.
      @user.password = SecureRandom.hex
      if @user.save
        redirect_to admin_accounts_url, notice: I18n.t('admin.accounts.create.success')
      else
        render :new
      end
    end

    def suspend
      Admin::SuspensionWorker.perform_async(@account.id)
      redirect_to admin_accounts_path
    end

    def unsuspend
      @account.update(suspended: false)
      redirect_to admin_accounts_path
    end

    def silence
      @account.update(silenced: true)
      redirect_to admin_accounts_path
    end

    def unsilence
      @account.update(silenced: false)
      redirect_to admin_accounts_path
    end

    def edit
      redirect_to admin_account_path(@account.id) unless @account.local?
      @user = @account.user
    end

    def update
      redirect_to admin_account_path(@account.id) unless @account.local?
      @user = @account.user
      if @user.update(credentials_params)
        redirect_to admin_account_path(@account.id), notice: I18n.t('generic.changes_saved_msg')
      else
        render action: :edit
      end
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:silenced, :suspended)
    end

    def user_params
      account_attr = { account_attributes: [:username] }
      params.require(:user).permit(:email, account_attr)
    end

    def credentials_params
      new_params = params.require(:user).permit(:email, :password, :password_confirmation)
      if new_params[:password].blank? && new_params[:password_confirmation].blank?
        new_params.delete(:password)
        new_params.delete(:password_confirmation)
      end
      new_params
    end
  end
end
