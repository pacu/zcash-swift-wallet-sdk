//
//  MockTransactionRepository.swift
//  ZcashLightClientKit-Unit-Tests
//
//  Created by Francisco Gindre on 12/6/19.
//

import Foundation
@testable import ZcashLightClientKit

class MockTransactionRepository {
    enum Kind {
        case sent
        case received
    }

    var unminedCount: Int
    var receivedCount: Int
    var sentCount: Int
    var scannedHeight: BlockHeight
    var reference: [Kind] = []
    var network: ZcashNetwork

    var transactionsNG: [TransactionNG.Overview] = []
    var receivedTransactionsNG: [TransactionNG.Received] = []
    var sentTransactionsNG: [TransactionNG.Sent] = []

    var allCount: Int {
        receivedCount + sentCount
    }

    init(
        unminedCount: Int,
        receivedCount: Int,
        sentCount: Int,
        scannedHeight: BlockHeight,
        network: ZcashNetwork
    ) {
        self.unminedCount = unminedCount
        self.receivedCount = receivedCount
        self.sentCount = sentCount
        self.scannedHeight = scannedHeight
        self.network = network
    }

    func referenceArray() -> [Kind] {
        var template: [Kind] = []
        
        for _ in 0 ..< sentCount {
            template.append(.sent)
        }
        for _ in 0 ..< receivedCount {
            template.append(.received)
        }

        return template.shuffled()
    }
    
    func randomBlockHeight() -> BlockHeight {
        BlockHeight.random(in: network.constants.saplingActivationHeight ... 1_000_000)
    }

    func randomTimeInterval() -> TimeInterval {
        Double.random(in: Date().timeIntervalSince1970 - 1000000.0 ... Date().timeIntervalSince1970)
    }
}

extension MockTransactionRepository.Kind: Equatable {}

// MARK: - TransactionRepository
extension MockTransactionRepository: TransactionRepository {
    func countAll() throws -> Int {
        allCount
    }

    func countUnmined() throws -> Int {
        unminedCount
    }

    func blockForHeight(_ height: BlockHeight) throws -> Block? {
        nil
    }

    func findBy(id: Int) throws -> TransactionNG.Overview? {
        transactionsNG.first(where: { $0.id == id })
    }

    func findBy(rawId: Data) throws -> TransactionNG.Overview? {
        transactionsNG.first(where: { $0.rawID == rawId })
    }

    func lastScannedHeight() throws -> BlockHeight {
        return scannedHeight
    }

    func isInitialized() throws -> Bool {
        true
    }
}

enum MockTransactionRepositoryError: Error {
    case notImplemented
}

extension MockTransactionRepository {
    func generateNG() {
        var txArray: [TransactionNG.Overview] = []
        reference = referenceArray()
        for index in 0 ..< reference.count {
            txArray.append(mockTx(index: index, kind: reference[index]))
        }
        transactionsNG = txArray
    }

    func mockTx(index: Int, kind: Kind) -> TransactionNG.Overview {
        switch kind {
        case .received:
            return mockReceived(index)
        case .sent:
            return mockSent(index)
        }
    }

    func mockSent(_ index: Int) -> TransactionNG.Overview {
        return TransactionNG.Overview(
            blocktime: randomTimeInterval(),
            expiryHeight: BlockHeight.max,
            fee: Zatoshi(2),
            id: index,
            index: index,
            isWalletInternal: true,
            hasChange: true,
            memoCount: 0,
            minedHeight: randomBlockHeight(),
            raw: Data(),
            rawID: Data(),
            receivedNoteCount: 0,
            sentNoteCount: 1,
            value: Zatoshi(-Int64.random(in: 1 ... Zatoshi.Constants.oneZecInZatoshi))
        )
    }

    func mockReceived(_ index: Int) -> TransactionNG.Overview {
        return TransactionNG.Overview(
            blocktime: randomTimeInterval(),
            expiryHeight: BlockHeight.max,
            fee: Zatoshi(2),
            id: index,
            index: index,
            isWalletInternal: true,
            hasChange: true,
            memoCount: 0,
            minedHeight: randomBlockHeight(),
            raw: Data(),
            rawID: Data(),
            receivedNoteCount: 1,
            sentNoteCount: 0,
            value: Zatoshi(Int64.random(in: 1 ... Zatoshi.Constants.oneZecInZatoshi))
        )
    }

    func slice(txs: [TransactionNG.Overview], offset: Int, limit: Int) -> [TransactionNG.Overview] {
        guard offset < txs.count else { return [] }

        return Array(txs[offset ..< min(offset + limit, txs.count - offset)])
    }

    func find(id: Int) throws -> TransactionNG.Overview {
        guard let transaction = transactionsNG.first(where: { $0.id == id }) else {
            throw TransactionRepositoryError.notFound
        }

        return transaction
    }

    func find(rawID: Data) throws -> TransactionNG.Overview {
        guard let transaction = transactionsNG.first(where: { $0.rawID == rawID }) else {
            throw TransactionRepositoryError.notFound
        }

        return transaction
    }

    func find(offset: Int, limit: Int, kind: TransactionKind) throws -> [ZcashLightClientKit.TransactionNG.Overview] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func find(in range: BlockRange, limit: Int, kind: TransactionKind) throws -> [TransactionNG.Overview] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func find(from: TransactionNG.Overview, limit: Int, kind: TransactionKind) throws -> [TransactionNG.Overview] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func findReceived(offset: Int, limit: Int) throws -> [TransactionNG.Received] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func findSent(offset: Int, limit: Int) throws -> [TransactionNG.Sent] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func findSent(in range: BlockRange, limit: Int) throws -> [TransactionNG.Sent] {
        throw MockTransactionRepositoryError.notImplemented
    }

    func findSent(rawID: Data) throws -> TransactionNG.Sent {
        throw MockTransactionRepositoryError.notImplemented
    }
}

extension Array {
    func indices(where function: (_ element: Element) -> Bool) -> [Int]? {
        guard !self.isEmpty else { return nil }

        var idx: [Int] = []

        for index in 0 ..< self.count {
            if function(self[index]) {
                idx.append(index)
            }
        }
        
        guard !idx.isEmpty else { return nil }
        return idx
    }
}
