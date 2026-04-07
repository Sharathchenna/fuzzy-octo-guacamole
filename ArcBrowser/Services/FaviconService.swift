import Foundation
import SwiftUI
import AppKit

// MARK: - Favicon Service
// Fetches and caches website favicons using Google's favicon service

class FaviconService {
    static let shared = FaviconService()
    
    // Cache for favicon images
    private var cache: [String: NSImage] = [:]
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let maxCacheSize = 100 // Maximum number of cached favicons in memory
    
    // Google's favicon service endpoint
    private let googleFaviconURL = "https://www.google.com/s2/favicons"
    
    init() {
        // Create cache directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.arcbrowser.clone"
        cacheDirectory = appSupportURL.appendingPathComponent(bundleID).appendingPathComponent("FaviconCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // Load cached favicons from disk
        loadCachedFavicons()
    }
    
    // MARK: - Public Methods
    
    /// Get favicon for a URL - returns cached image or fetches from network
    func getFavicon(for url: URL, completion: @escaping (NSImage?) -> Void) {
        let domain = getDomain(from: url)
        let cacheKey = domain
        
        // Check memory cache first
        if let cachedImage = cache[cacheKey] {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadFaviconFromDisk(for: domain) {
            cache[cacheKey] = diskImage
            completion(diskImage)
            return
        }
        
        // Fetch from network
        fetchFavicon(for: domain) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }
            
            // Cache in memory
            self.cache[cacheKey] = image
            
            // Save to disk
            self.saveFaviconToDisk(image, for: domain)
            
            // Manage cache size
            self.trimCacheIfNeeded()
            
            completion(image)
        }
    }
    
    /// Get favicon for a domain string (synchronous for known domains)
    func getFavicon(forDomain domain: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: "https://\(domain)") else {
            completion(nil)
            return
        }
        getFavicon(for: url, completion: completion)
    }
    
    /// Synchronous cached favicon (returns nil if not in cache)
    func cachedFavicon(for domain: String) -> NSImage? {
        return cache[domain]
    }
    
    /// Clear all cached favicons
    func clearCache() {
        cache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    // MARK: - Private Methods
    
    private func getDomain(from url: URL) -> String {
        guard let host = url.host else {
            return url.absoluteString
        }
        // Remove www. prefix for consistency
        return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
    }
    
    private func fetchFavicon(for domain: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: "\(googleFaviconURL)?domain=\(domain)&sz=128") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let image = NSImage(data: data)
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
    
    private func loadCachedFavicons() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files where file.pathExtension == "png" {
            if let data = try? Data(contentsOf: file),
               let image = NSImage(data: data) {
                let domain = file.deletingPathExtension().lastPathComponent
                cache[domain] = image
            }
        }
    }
    
    private func loadFaviconFromDisk(for domain: String) -> NSImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(domain).png")
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    private func saveFaviconToDisk(_ image: NSImage, for domain: String) {
        guard let data = image.pngData else { return }
        let fileURL = cacheDirectory.appendingPathComponent("\(domain).png")
        try? data.write(to: fileURL)
    }
    
    private func trimCacheIfNeeded() {
        guard cache.count > maxCacheSize else { return }
        
        // Remove oldest entries (randomly for now, could be improved with LRU)
        let keysToRemove = Array(cache.keys).prefix(cache.count - maxCacheSize)
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
}

// MARK: - NSImage Extension
extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}

// MARK: - Favicon Async Image
struct FaviconAsyncImage: View {
    let domain: String
    let size: CGFloat
    let fallback: String
    
    @State private var image: NSImage?
    @State private var isLoading = true
    
    init(domain: String, size: CGFloat = 16, fallback: String = "globe") {
        self.domain = domain
        self.size = size
        self.fallback = fallback
    }
    
    init(url: String, size: CGFloat = 16, fallback: String = "globe") {
        // Extract domain from URL
        if let urlObj = URL(string: url),
           let host = urlObj.host {
            self.domain = host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        } else {
            self.domain = url
        }
        self.size = size
        self.fallback = fallback
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                // Show nothing while loading for cleaner UI
                Color.clear
            } else {
                // Fallback to SF Symbol
                Image(systemName: fallback)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            FaviconService.shared.getFavicon(forDomain: domain) { fetchedImage in
                self.image = fetchedImage
                self.isLoading = false
            }
        }
    }
}
