Pod::Spec.new do |s|

  s.name = "Card_Scanner"
  s.version = "0.2.0"
  s.summary = "SwiftUI payment cards scanning tool."

  s.swift_version = '5.6'
  s.platform = :ios
  s.ios.deployment_target = '13.0'

  s.description = <<-DESC
  SwiftUI payment card scanning tool.
  DESC

  s.homepage = "https://github.com/michzio/CardScanner"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Michał Ziobro" => "swiftui.developer@gmail.com" }

  s.source = { :git => "https://github.com/michzio/CardScanner.git", :tag => "#{s.version}" }

  s.source_files = "Sources/**/*.swift"
  s.exclude_files = [
    "Example/**/*.swift", 
    "Tests/**/*.swift"
  ]

  s.framework = "UIKit"
  
end
