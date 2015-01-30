Pod::Spec.new do |s|
  s.name             = "Snapcache"
  s.version          = "0.1"
  s.summary          = "An NSCache-backed image cache in Swift."
  s.license          = 'MIT'
  s.homepage         = 'http://www.harlanhaskins.com'
  s.author           = { "Harlan Haskins" => "harlan@harlanhaskins.com" }
  s.source           = { :git => "https://github.com/harlanhaskins/Snapcache.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/harlanhaskins'

  s.requires_arc = true

  s.source_files = 'Snapcache/*.swift'
end
