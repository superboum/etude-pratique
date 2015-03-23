module EventController
  def self.registered(app) # <-- a method yes, but really a hook
    # FRONTOFFICE
    app.get '/event/:id/?' do
      event = Event.find_by_id(params[:id])
      puts authenticated?
      puts "reg #{event.registration}" 
      if authenticated?
       isRegistered = !user.registered?(event)
      else 
        isRegistered = false
      end
      haml :event, :locals => { :event => event,:registration => event.registration ,:isAuthentificated => authenticated?, :isRegistered => isRegistered}
    end


    app.get '/event/register/:id/?' do 
      restrictToAuthenticated!
      event = Event.find_by_id(params[:id])
      begin
        felts = FormElement.where(event_id: event.id)
      rescue
        felts= {}
      end
      haml :eventRegistration, :locals => {:event => event,:felts => felts}
    end


    app.post '/event/register/:id/?' do
      restrictToAuthenticated!
      if :id != params["event"] then 
        puts "error" #TODO 
      end
      begin
        felts = FormElement.where(event_id: params["id"])
      rescue 
        felts= {}
      end


      felts.each do |felt|
        fa = FormAnswer.new
        fa.form_elements_id = felt.id
        id="felt::#{felt.id}"
        puts felt.form_type
        case felt.form_type
        when FormElement.TYPES["bool"]
          if(params[id]=="1")
            fa.answer="true"
          else fa.answer = "false"
          end
        when FormElement.TYPES["select"]
          fa.answer =params[id]      
        when FormElement.TYPES["string"]
          fa.answer = params[id]
        else
          #TODO
          puts "\033[31merror\033[0m"
        end
        fa.save

        ufa = UsersFormAnswer.new
        ufa.form_answers_id = fa.id
        ufa.users_id = user.id
        ufa.save

      end


      participant = RegisteredUsersToEvents.new
      participant.event_id = params[:id]
      participant.user_id = user.id

      participant.save


      redirect "/", 303

    end
    # USERSIDE
    app.get '/profile/event/?' do
      restrictToAuthenticated!
      haml :'profile/layout', :locals => { :menu => 1 }, :layout => :'layout'  do
        haml :'profile/event'
      end
    end

    #BACKOFFICE
    app.get '/admin/event/?' do
      restrictToAdmin!
      events = Event.all


      haml :'admin/layout', :layout => :'layout'  do
        haml :'admin/event/home', :locals => { :events => events }
      end
    end


    app.get '/admin/event/new/?' do
      restrictToAdmin!
      haml :'admin/layout', :layout => :'layout' do
        haml :'admin/event/newedit', :locals => { :event => Event.new, :edit => false, :unvalid =>false  }
      end
    end


    app.post '/admin/event/new/?' do
      restrictToAdmin!
      event = Event.new
      event.name = params['name']
      event.short_text = params['short_text']
      event.start_date = params['start_date']
      event.end_date = params['end_date']
      event.place_number = params['place_number']
      event.registration= params['registration']=="1"
      event.user_id = user.id

      if(event.invalid?) 

        puts event.errors.messages
        haml :'admin/layout', :layout => :'layout' do
          haml :'admin/event/newedit', :locals => { :event => event, :edit => false, :unvalid => true, :errors =>event.errors.messages }
        end
      else
        event.save
        if(params['add_form_element']=='1')   
          redirect "/admin/form_element/new/#{event.id}"
        end
        redirect "/admin/event", 303
      end
    end

    app.get '/admin/event/edit/:id/?' do
      restrictToAdmin!
      event = Event.find(params[:id])
      begin
        felts = FormElement.where(event_id: event.id)
      rescue
        felts= {}
      end
      haml :'admin/layout', :layout => :'layout' do
        haml :'admin/event/newedit', :locals => { :event => event, :felts => felts,:unvalid => false,:edit => true }
      end

    end


    app.post '/admin/event/edit/:id' do
      restrictToAdmin!
      event = Event.find(params[:id])
      event.name = params['name']
      event.short_text = params['short_text']
      event.start_date = params['start_date']
      event.end_date = params['end_date']
      event.registration= params['registration']=="1"
      event.place_number = params['place_number']
      event.user_id = user.id

      event.save

      begin
        felts = FormElement.where(event_id: event.id)
        rescue
        felts= {}
      end

      felts.each do |felt|
        felt.question= params['question::'+felt.id.to_s]
        felt.form_type = params["form_type::"+felt.id.to_s]
        felt.event_id = params["event::"+felt.id.to_s]
        if felt.form_type == FormElement.TYPES["select"]
          puts "Data"
          felt.data=params["dataSelect::"+felt.id.to_s]
        end
        felt.save

      end

      if(event.invalid?) 

        puts event.errors.messages
        haml :'admin/layout', :layout => :'layout' do
          haml :'admin/event/newedit', :locals => { :event => event, :felts=>felts,:edit => true, :unvalid => true, :errors =>event.errors.messages }
        end
      else

        if(params['add_form_element']=='1')   
          redirect "/admin/form_element/new/#{event.id}"
        end
        redirect "/admin/event", 303
      end
    end


    app.get '/admin/event/delete/:id/?' do
      restrictToAdmin!
      event = Event.find(params[:id])
      haml :'admin/layout', :layout => :'layout' do
        haml :'admin/event/delete', :locals => { :event => event }
      end
    end

    app.post '/admin/event/delete/:id' do
      restrictToAdmin!
      Event.destroy(params[:id])
      redirect "/admin/event", 303
    end
  end
end
