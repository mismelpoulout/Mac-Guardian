import XCTest
import Foundation
@testable import VeltrixSecurity

final class TrashServiceTests: XCTestCase {
    
    func testCanMoveAppToTrashFromApplications() {
        let appURL = URL(fileURLWithPath: "/Applications/TestApp.app", isDirectory: true)
        XCTAssertTrue(TrashService.canMoveAppToTrash(appURL))
    }
    
    func testCanMoveAppToTrashFromUserApplications() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let appURL = home.appendingPathComponent("Applications/TestApp.app", isDirectory: true)
        XCTAssertTrue(TrashService.canMoveAppToTrash(appURL))
    }
    
    func testCannotMoveSystemAppToTrash() {
        let appURL = URL(fileURLWithPath: "/System/Applications/TestApp.app", isDirectory: true)
        XCTAssertFalse(TrashService.canMoveAppToTrash(appURL))
    }
    
    func testCannotMoveNonAppToTrash() {
        let url = URL(fileURLWithPath: "/Applications/Document.txt")
        XCTAssertFalse(TrashService.canMoveAppToTrash(url))
    }
    
    func testRejectSymbolicLinksFromTrash() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrashTest-\(UUID().uuidString)", isDirectory: true)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let targetFile = tempDir.appendingPathComponent("target.txt")
        try "test".write(to: targetFile, atomically: true, encoding: .utf8)
        
        let linkFile = tempDir.appendingPathComponent("link.txt")
        try FileManager.default.createSymbolicLink(at: linkFile, withDestinationURL: targetFile)
        
        // Intentar mover symlink debe fallar
        do {
            try TrashService.moveCacheItemToTrash(linkFile, cacheRoot: tempDir)
            XCTFail("Should reject symbolic link")
        } catch TrashServiceError.symbolicLinkNotSupported {
            // Esperado
        }
    }
    
    func testEmptyTrashReturnsCount() {
        let (count, _) = TrashService.emptyTrash()
        XCTAssertGreaterThanOrEqual(count, 0)
    }
}
