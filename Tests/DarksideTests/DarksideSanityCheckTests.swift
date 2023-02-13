//
//  DarksideSanityCheckTests.swift
//  ZcashLightClientKit-Unit-Tests
//
//  Created by Francisco Gindre on 5/21/20.
//

import Foundation
@testable import TestUtils
import XCTest
@testable import ZcashLightClientKit

class DarksideSanityCheckTests: XCTestCase {
    // TODO: [#715] Parameterize this from environment, https://github.com/zcash/ZcashLightClientKit/issues/715?
    // swiftlint:disable:next line_length
    var seedPhrase = "still champion voice habit trend flight survey between bitter process artefact blind carbon truly provide dizzy crush flush breeze blouse charge solid fish spread"
    // TODO: [#715] Parameterize this from environment, https://github.com/zcash/ZcashLightClientKit/issues/715
    let testRecipientAddress = "zs17mg40levjezevuhdp5pqrd52zere7r7vrjgdwn5sj4xsqtm20euwahv9anxmwr3y3kmwuz8k55a"

    let sendAmount: Int64 = 1000
    var birthday: BlockHeight = 663150
    let defaultLatestHeight: BlockHeight = 663175
    var coordinator: TestCoordinator!
    var syncedExpectation = XCTestExpectation(description: "synced")
    var sentTransactionExpectation = XCTestExpectation(description: "sent")
    var expectedReorgHeight: BlockHeight = 665188
    var expectedRewindHeight: BlockHeight = 665188
    var network = DarksideWalletDNetwork()
    var reorgExpectation = XCTestExpectation(description: "reorg")
    let branchID = "2bb40e60"
    let chainName = "main"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.coordinator = try TestCoordinator(
            seed: self.seedPhrase,
            walletBirthday: self.birthday,
            network: self.network
        )

        try self.coordinator.reset(saplingActivation: self.birthday, branchID: self.branchID, chainName: self.chainName)
        try self.coordinator.resetBlocks(dataset: .default)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try? FileManager.default.removeItem(at: coordinator.databases.fsCacheDbRoot)
        try? FileManager.default.removeItem(at: coordinator.databases.dataDB)
        try? FileManager.default.removeItem(at: coordinator.databases.pendingDB)
    }
    
    func testDarkside() throws {
        let expectedFirstBlock = (height: BlockHeight(663150), hash: "0000000002fd3be4c24c437bd22620901617125ec2a3a6c902ec9a6c06f734fc")
        let expectedLastBlock = (height: BlockHeight(663200), hash: "2fc7b4682f5ba6ba6f86e170b40f0aa9302e1d3becb2a6ee0db611ff87835e4a")
        
        try coordinator.applyStaged(blockheight: expectedLastBlock.height)

        sleep(1)
        
        let syncExpectation = XCTestExpectation(description: "sync to \(expectedLastBlock.height)")
        
        try coordinator.sync(
            completion: { _ in
                syncExpectation.fulfill()
            },
            error: { error in
                guard let error else {
                    XCTFail("failed with unknown error")
                    return
                }
                XCTFail("failed with error: \(error)")
                return
            }
        )
        
        wait(for: [syncExpectation], timeout: 5)
        
        let blocksDao = BlockSQLDAO(dbProvider: SimpleConnectionProvider(path: coordinator.databases.dataDB.absoluteString, readonly: false))
        
        let firstBlock = try blocksDao.block(at: expectedFirstBlock.height)
        let lastBlock = try blocksDao.block(at: expectedLastBlock.height)
        
        XCTAssertEqual(firstBlock?.hash.toHexStringTxId(), expectedFirstBlock.hash)
        XCTAssertEqual(lastBlock?.hash.toHexStringTxId(), expectedLastBlock.hash)
    }
}
