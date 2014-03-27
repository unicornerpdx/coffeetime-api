class App < Jsonatra::Base

  configure do
    set :arrayified_params, [:keys]    
  end

  get '/' do
    {
      hello: 'world'
    }
  end


end
