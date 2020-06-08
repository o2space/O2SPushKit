Pod::Spec.new do |s|
  s.name             = 'O2SPushKit'
  s.version          = "1.0.0"
  s.summary          = 'iOS 新老版本推送整合，统一API及输出'
  s.license          = 'MIT'
  s.author           = { "o2space" => "o2space@163.com" }

  s.homepage         = 'http://www.by2code.com'
  s.source           = { :git => 'https://github.com/o2space/O2SPushKit.git', :tag => s.version.to_s }
  s.platform         = :ios
  s.ios.deployment_target = "8.0"
  #s.frameworks       = 'UserNotifications'
  s.libraries        = 'c++'
  s.default_subspecs = 'O2SPushKit'

  # 核心模块
  s.subspec 'O2SPushKit' do |sp|
      sp.vendored_frameworks = 'O2SPACE_SDK/O2SPushSDK/O2SPushKit.framework'
  end

end
