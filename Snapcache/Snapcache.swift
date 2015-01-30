//
//  Snapcache.swift
//  
//
//  Created by Harlan Haskins on 11/17/14.
//
//

import UIKit

private let sharedInstance = Snapcache()
private let requestQueue = dispatch_queue_create("com.snapcache.RequestsQueue", DISPATCH_QUEUE_SERIAL)
private let cacheQueue = dispatch_queue_create("com.snapcache.CacheQueue", DISPATCH_QUEUE_SERIAL)

let SnapcacheUserInfoFailingURLKey = "com.snapcache.FailingURLKey"

protocol Cacheable {
    var url: NSURL { get }
    var key: String { get }
    var type: String { get }
    func snapcache(manager: Snapcache, didLoadImage image: UIImage)
    func snapcache(manager: Snapcache, didFailWithError error: NSError)
}

class Snapcache {
    
    class var sharedCache: Snapcache {
        return sharedInstance
    }
    
    var cache = [String: NSCache]()
    var requests = [NSURL: [Cacheable]]()
    
    func loadImageForObject(object: Cacheable) {
        if let image = self.cachedImageForKey(object.key, type: object.type) {
            object.snapcache(self, didLoadImage:image)
        } else {
            self.addRequest(object: object)
        }
    }
    
    func cachedImageForKey(key: String, type: String) -> UIImage? {
        return self.cache[type]?.objectForKey(key) as? UIImage
    }
    
    func cacheImage(image: UIImage, key: String, type: String) {
        let collection = self.cache[type] ?? NSCache()
        collection.setObject(image, forKey: key)
        self.cache[type] = collection
    }
    
    func setImage(image: UIImage, atURL url: NSURL, forKey key: String, withType type: String) {
        dispatch_async(cacheQueue) {
            self.cacheImage(image, key: key, type: type)
            self.runCompletionsForURL(url, image: image, error: nil)
        }
    }
    
    private func addRequest(#object: Cacheable) {
        dispatch_async(requestQueue) {
            var existingRequests = self.requests[object.url]
            var newRequests: [Cacheable]
            if let requests = existingRequests {
                newRequests = requests + [object]
            } else {
                newRequests = [object]
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                    self.loadAssetForURL(object.url, key: object.key, type: object.type)
                    return
                }
            }
            self.requests[object.url] = newRequests
        }
    }
    
    private func loadAssetForURL(url: NSURL, key: String, type: String) {
        let request = NSMutableURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {data, response, error in
            if let error = error {
                self.runCompletionsForURL(url, image: nil, error: error)
            } else if let data = data {
                if let image = UIImage(data: data) {
                    self.setImage(image, atURL: url, forKey: key, withType: type)
                    return
                }
            }
            let error = NSError(domain: "Failed to load resource", code: 0xbadb33f, userInfo: [SnapcacheUserInfoFailingURLKey: url])
            self.runCompletionsForURL(url, image: nil, error: error)
        }
        task.resume()
    }
    
    private func runCompletionsForURL(url: NSURL, image: UIImage?, error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) {
            if let requests = self.requests[url] {
                for object in requests {
                    if let image = image {
                        object.snapcache(self, didLoadImage: image)
                    } else if let error = error {
                        object.snapcache(self, didFailWithError: error)
                    }
                }
                self.requests[url] = nil
            }
        }
    }
    
}
