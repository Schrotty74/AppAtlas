import Foundation

struct LocalAppFile: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let fileName: String
    let fileType: String
    let sourceCategory: String
    let sourceSubcategory: String
    let relativePath: String
    let sizeInBytes: Int64
    let modifiedAt: Date?
    let detectedVersion: String?
    let iconData: Data?

    init(
        id: UUID = UUID(),
        fileName: String,
        fileType: String,
        sourceCategory: String,
        sourceSubcategory: String,
        relativePath: String,
        sizeInBytes: Int64,
        modifiedAt: Date?,
        detectedVersion: String?,
        iconData: Data? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.sourceCategory = sourceCategory
        self.sourceSubcategory = sourceSubcategory
        self.relativePath = relativePath
        self.sizeInBytes = sizeInBytes
        self.modifiedAt = modifiedAt
        self.detectedVersion = detectedVersion
        self.iconData = iconData
    }

    func removingIconData() -> LocalAppFile {
        LocalAppFile(
            id: id,
            fileName: fileName,
            fileType: fileType,
            sourceCategory: sourceCategory,
            sourceSubcategory: sourceSubcategory,
            relativePath: relativePath,
            sizeInBytes: sizeInBytes,
            modifiedAt: modifiedAt,
            detectedVersion: detectedVersion
        )
    }
}
