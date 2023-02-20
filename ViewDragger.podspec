Pod::Spec.new do |s|
  s.name             = 'ViewDragger'
  s.version          = '1.0.0'
  s.summary          = 'A tiny tool to provide draggable function to any UIView.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/vince-hz/ViewDragger'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vince-hz' => 'zjxuyunshi@gmail.com' }
  s.source           = { :git => 'https://github.com/vince-hz/ViewDragger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'ViewDragger/Classes/**/*'
  
end
