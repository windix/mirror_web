require 'rubygems'
require 'sinatra'
require 'rchardet'

get '/' do
  erb :index
end

post '/guess' do
  if params[:content]
    content = params[:content].strip

    cd = CharDet.detect(content)
    encoding = cd['encoding']
    encoding = "GBK" if encoding == "GB2312"

    encoding
  end
end

__END__

@@ index
<h1>Services</h1>
<h2>/guess</h2>
<p>method: POST, parameter: content, result: encoding</p>
