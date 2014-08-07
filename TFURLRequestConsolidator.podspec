Pod::Spec.new do |s|
  s.name             = "TFURLRequestConsolidator"
  s.version          = "1.0.1"
  s.summary          = "TFURLRequestConsolidator helps to prevent from sending multiple requests to the same endpoint on the server" 
  s.description      = "TFURLRequestConsolidator helps to prevent from sending multiple requests to the same endpoint on the server by consolidating them into the one that is already ongoing"
  s.homepage         = "https://github.com/TriforkKRK/TFURLRequestConsolidator"
  
  s.license          = { :type => 'Apache v2', :file => 'LICENSE' }
  s.author           = { "Bartlomiej Hyzy" => "hyzy.bartlomiej@gmail.com" }
  s.source           = { :git => "https://github.com/TriforkKRK/TFURLRequestConsolidator.git", :tag => s.version.to_s }

  s.platform         = :ios, '7.0'
  s.requires_arc     = true
  s.source_files     = 'Pod/**/*.{h,m}'
end
