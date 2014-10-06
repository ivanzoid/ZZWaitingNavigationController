Pod::Spec.new do |s|
  s.name             = "ZZWaitingNavigationController"
  s.version          = '0.9'
  s.summary          = "UINavigationController subclass which postpones actions until animation finishes."
  s.description      = <<-DESC
					   Automatically postpones actions like push/pop/set view controller(s) in a case if animation is in progress and performs them when animation is finished.
  s.homepage         = "https://github.com/ivanzoid/ZZWaitingNavigationController"
  s.license          = 'MIT'
  s.author           = { "Ivan Zezyulya" => "ZZWaitingNavigationControllern@zoid.cc" }
  s.source           = { :git => "https://github.com/ivanzoid/ZZWaitingNavigationController.git", :tag => s.version.to_s }
  s.platform     = :ios
  s.requires_arc = true
  s.source_files = 'Source'
end

