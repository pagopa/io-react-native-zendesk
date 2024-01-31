require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = "pagopa-io-react-native-crypto"
  s.version        = package['version']
  s.summary        = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { git: "https://github.com/pagopa/io-react-native-zendesk.git", :tag => "#{s.version}" }
  s.requires_arc   = true
  s.platform       = :ios, '11.0'

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json', 'index.js'
  s.source_files   = 'ios/*.{h,m}'

  s.dependency 'React'
  s.dependency 'ZendeskAnswerBotSDK', '~> 5.0.0'
  s.dependency 'ZendeskSupportSDK', '~> 8.0.0'
  s.dependency 'ZendeskChatSDK', '~> 5.0.0'
  s.dependency 'ZendeskMessagingAPISDK', '~> 6.0.0'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
