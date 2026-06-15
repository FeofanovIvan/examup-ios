import Foundation

/// Minimal ZIP writer (Store method, no compression).
/// Suitable for archiving SafeMode capture folders — JPEGs and PDFs are
/// already compressed, so Store is appropriate and avoids any dependency.
enum ZipArchiveCreator {

    /// Creates a ZIP file at `destinationURL` containing all files in `folderURL`.
    /// Relative paths within the ZIP preserve the source folder structure.
    static func createZip(from folderURL: URL, to destinationURL: URL) throws {
        var localHeaders = Data()   // local header + file data sections
        var centralDir  = Data()   // central directory entries
        var fileCount: UInt16 = 0

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let fileURL as URL in enumerator {
            let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard !isDir else { continue }

            let relativePath = String(fileURL.path.dropFirst(folderURL.path.count + 1))
            guard !relativePath.isEmpty else { continue }

            let fileData   = try Data(contentsOf: fileURL)
            let crc        = crc32(fileData)
            let nameData   = Data(relativePath.utf8)
            let localOffset = UInt32(localHeaders.count)

            // ── Local file header ─────────────────────────────────────────────
            var lh = Data()
            lh.appendLE(UInt32(0x04034b50)) // signature
            lh.appendLE(UInt16(20))          // version needed
            lh.appendLE(UInt16(0))           // flags
            lh.appendLE(UInt16(0))           // compression: Store
            lh.appendLE(UInt16(0))           // mod time
            lh.appendLE(UInt16(0))           // mod date
            lh.appendLE(crc)                  // CRC-32
            lh.appendLE(UInt32(fileData.count)) // compressed size
            lh.appendLE(UInt32(fileData.count)) // uncompressed size
            lh.appendLE(UInt16(nameData.count)) // filename length
            lh.appendLE(UInt16(0))           // extra field length
            lh.append(nameData)

            localHeaders.append(lh)
            localHeaders.append(fileData)

            // ── Central directory entry ───────────────────────────────────────
            var cd = Data()
            cd.appendLE(UInt32(0x02014b50)) // signature
            cd.appendLE(UInt16(20))          // version made by
            cd.appendLE(UInt16(20))          // version needed
            cd.appendLE(UInt16(0))           // flags
            cd.appendLE(UInt16(0))           // compression
            cd.appendLE(UInt16(0))           // mod time
            cd.appendLE(UInt16(0))           // mod date
            cd.appendLE(crc)
            cd.appendLE(UInt32(fileData.count))
            cd.appendLE(UInt32(fileData.count))
            cd.appendLE(UInt16(nameData.count))
            cd.appendLE(UInt16(0))           // extra field length
            cd.appendLE(UInt16(0))           // comment length
            cd.appendLE(UInt16(0))           // disk number
            cd.appendLE(UInt16(0))           // internal attrs
            cd.appendLE(UInt32(0))           // external attrs
            cd.appendLE(localOffset)          // local header offset
            cd.append(nameData)

            centralDir.append(cd)
            fileCount += 1
        }

        let cdOffset = UInt32(localHeaders.count)

        // ── End of central directory ──────────────────────────────────────────
        var eocd = Data()
        eocd.appendLE(UInt32(0x06054b50)) // signature
        eocd.appendLE(UInt16(0))           // disk number
        eocd.appendLE(UInt16(0))           // disk with CD start
        eocd.appendLE(fileCount)            // entries on this disk
        eocd.appendLE(fileCount)            // total entries
        eocd.appendLE(UInt32(centralDir.count)) // CD size
        eocd.appendLE(cdOffset)             // CD offset
        eocd.appendLE(UInt16(0))           // comment length

        var zip = localHeaders
        zip.append(centralDir)
        zip.append(eocd)

        try zip.write(to: destinationURL, options: [.atomic])
    }

    // MARK: - CRC-32

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB8_8320 : crc >> 1
            }
        }
        return ~crc
    }
}

// MARK: - Data helper

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { self.append(contentsOf: $0) }
    }
}
