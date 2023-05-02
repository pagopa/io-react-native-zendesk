require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'RNZendeskChat'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { git: "https://github.com/Saranshmalik/react-native-zendesk.git" }
  s.requires_arc   = true
  s.platform       = :ios, '11.0'

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json', 'index.js'
  s.source_files   = 'ios/*.{h,m}'

  s.dependency 'React'
  s.dependency 'ZendeskAnswerBotSDK', '~> 3.0.0'
  s.dependency 'ZendeskSupportSDK', '~> 6.0.0'
  s.dependency 'ZendeskChatSDK', '~> 3.0.0'
  s.dependency 'ZendeskMessagingAPISDK', '~> 4.0.0'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
