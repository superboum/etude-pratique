class MainController < BaseController
  # FRONTOFFICE
  get '/' do
    articles = Article.all
    events = Event.order(:start_date)
    haml :'home', :locals => { :articles => articles, :events => events }
  end

  get '/login' do
    haml :login
  end

  post '/login' do
	email=params['emailSI']
	rawPassword=params['InputPasswordSI']
	password=Digest::SHA256.hexdigest("#{rawPassword}")
	if User.where("email=? AND password=?",email,password).count == 1 then
	redirect to('/'), 303
	else
	redirect to('/login'),303
	end
  end

  # BACKOFFICE
  get '/admin' do
    articles = Article.all
    events = Event.all
    haml :'admin/layout', :layout => :'layout' do
      haml :'admin/home', :locals => { :articles => articles, :events => events}
    end
  end
end
