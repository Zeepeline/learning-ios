//
//  ImageCacheManager.swift
//  learning
//
//  Created by macbook on 9/18/26.
//

import UIKit
import SwiftUI
import ImageIO

// MARK: - 🚀 High-Performance Image Cache & Downsampler (ProMotion 120 FPS Optimized)
@MainActor
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Batasi penggunaan memori cache (max 40 thumbnail)
        cache.countLimit = 40
        cache.totalCostLimit = 1024 * 1024 * 20 // 20 MB max
    }

    /// Mengambil thumbnail berukuran tepat secara instan dari cache atau mendownsample secara efisien tanpa lag memori
    func thumbnail(for data: Data?, key: String, targetSize: CGSize = CGSize(width: 120, height: 120)) -> UIImage? {
        guard let data = data, !data.isEmpty else { return nil }

        let cacheKey = NSString(string: "\(key)_\(Int(targetSize.width))x\(Int(targetSize.height))")
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Downsampling hemat memori menggunakan ImageIO
        if let downsampled = downsample(imageData: data, to: targetSize) {
            cache.setObject(downsampled, forKey: cacheKey, cost: downsampled.pngData()?.count ?? 1024)
            return downsampled
        }

        return UIImage(data: data)
    }

    /// Membersihkan cache saat memori terbatas
    func clearMemory() {
        cache.removeAllObjects()
    }

    // MARK: - Core Graphics Low-Memory Downsampling
    private func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}
