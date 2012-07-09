module Sinatra
  module AuthHelpers

    def current_user
      session.delete :authentication_id   # Clean up old auth values
      begin
        if session[:user_id] && session[:authentication_provider]
          @current_auth ||= Authentication.first(:user_id => session[:user_id],
                                  :provider => session[:authentication_provider]
                                               )
          @current_user ||= @current_auth.user
        end
        return @current_user if @current_user
      rescue      # =>  Invalid cookie value formats?
        @current_user = nil
        @current_auth = nil
      end

      # Clean up any old/bad cookie values:
      session.delete :user_id
      session.delete :authentication_provider
    end

    def current_auth
      current_user
      @current_auth
    end

    def authenticate
      authentication_route = params[:name] ? params[:name] : 'No authentication recognized (invalid callback)'
      # get the full hash from omniauth
      omniauth = request.env['omniauth.auth']

      # continue only if hash and parameter exist
      unless omniauth and params[:name]
        flash[:error] = "Error while authenticating via #{authentication_route.capitalize}. The authentication did not return valid data."
        redirect to '/'
      end

      # create a new regularised authentication hash
      @authhash = Hash.new
      oaeuh = omniauth['extra'] && (omniauth['extra']['user_hash'] ||
                                    omniauth['extra']['raw_info'])
      oaui = omniauth['user_info'] || omniauth['info']
      case authentication_route
        when "facebook"
        @authhash[:email] = oaeuh['email'] || ''
        @authhash[:name] = oaeuh['name'] || ''
        @authhash[:uid] = oaeuh['name'] || ''
        @authhash[:provider] = omniauth['provider'] || ''
      when "twitter"
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = omniauth['info']['nickname'] || ''
#        @authhash[:nick] = oaui['screen_name'] || ''
        @authhash[:uid] = (oaeuh['id'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      when 'github'
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (oaeuh['id'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      when 'google', 'yahoo', 'linked_in', 'twitter', 'myopenid', 'openid', 'open_id'
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (omniauth['uid'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      when 'aol'
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (omniauth['uid'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      else
        # REVISIT: debug to output the hash that has been returned when adding new authentications
        return '<pre>'+omniauth.to_yaml+'</pre>'
      end

      if @authhash[:uid] == '' or @authhash[:provider] == ''
        flash[:error] = 'Error while authenticating via #{authentication_route}/#{@authhash[:provider].capitalize} The authentication returned invalid data for the user id.'
        redirect to(session[:return_to])
      end

      auth = Authentication.first(:provider => @authhash[:provider],
                                    :uid => @authhash[:uid])
      # if the user is currently signed in, he/she might want to add another account to signin
      if current_user
        if auth
          flash[:notice] = "You are now signed in using your #{@authhash[:provider].capitalize} account"
          session[:user_id] ||= auth.user.id
          session[:authentication_provider] = auth.provider   # They're now signed in using the new account
          redirect to(session[:return_to])  # Already signed in, and we already had this authentication
        else
          auth = current_user.authentications.create!(:provider => @authhash[:provider], :uid => @authhash[:uid], :user_name => @authhash[:name], :user_email => @authhash[:email])
          flash[:notice] = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
          session[:authentication_provider] = auth.provider   # They're now signed in using the new account
          session[:user_name] = @authhash[:name] unless @authhash[:name].empty?
          redirect to(session[:return_to])
        end
      else
        if auth
          # Signin existing user
          # in the session his user id and the authentication id used for signing in is stored
          session[:user_id] = auth.user.id
          session[:authentication_provider] = auth.provider   # They're now signed in using the new account
          session[:user_name] = @authhash[:name] if @authhash[:name] != ''

          flash[:notice] = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
          redirect to(session[:return_to])
        end

        if email = @authhash[:email] and email != '' and
            auth = Authentication.first(:email => email)
          # Would have been seen as a new user, but instead we found that we know their email address already
          provider = @authhash[:provider]
          auth = auth.user.authentications.create!(
                                                   :provider => provider,
                                                   :uid => @authhash[:uid],
                                                   :user_name => @authhash[:name],
                                                   :user_email => @authhash[:email]
                                                   )
          flash[:notice] = 'Your ' + provider.capitalize + ' account has been added for signing in at this site.'
          session[:user_id] = auth.user.id
          session[:authentication_provider] = auth.provider   # They're now signed in using the new account
          session[:user_name] = @authhash[:name] if @authhash[:name] != ''
          redirect to(session[:return_to])
        end

        # this is a new user; add them
        @current_user = User.create()
        session[:user_id] = @current_user.id
        session[:user_name] = @authhash[:name] if @authhash[:name] != ''
        auth = current_user.authentications.create!(
                                                :provider => @authhash[:provider],
                                                :uid => @authhash[:uid],
                                                :user_name => @authhash[:name],
                                                :user_email => @authhash[:email]
                                                )
        session[:authentication_provider] = auth.provider
#        puts env['omniauth.auth'].to_yaml
      end
    end

    def authenticated?
      ! session[:user_id].nil?
    end
  end
end
