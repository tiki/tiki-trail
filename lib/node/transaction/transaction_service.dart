/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:sqlite3/common.dart';

import '../../utils/bytes.dart';
import '../../utils/merkel_tree.dart';
import '../../utils/rsa/rsa.dart';
import '../../utils/rsa/rsa_private_key.dart';
import '../../utils/rsa/rsa_public_key.dart';
import '../block/block_model.dart';
import '../key/key_model.dart';
import 'transaction_model.dart';
import 'transaction_repository.dart';

/// The service to manage transactions in the chain.
class TransactionService {
  final TransactionRepository _repository;
  final RsaPrivateKey? _appKey;

  TransactionService(CommonDatabase db, {RsaPrivateKey? appKey})
      : _repository = TransactionRepository(db),
        _appKey = appKey;

  /// Creates a [TransactionModel] with [contents].
  ///
  /// Uses the [KeyModel.privateKey] from [key] to sign the transaction. If the
  /// [assetRef] is not set, it defaults to ''. The return is an uncommitted
  /// [TransactionModel]. The [TransactionModel] should be added to a
  /// [BlockModel] by setting the [TransactionModel.block] and
  /// [TransactionModel.merkelProof] values and calling the [commit] method.
  TransactionModel create(Uint8List contents, KeyModel key,
      {String assetRef = ''}) {
    TransactionModel txn = TransactionModel(
        address: key.address, contents: contents, assetRef: assetRef);
    Uint8List serializedWithoutSigs = txn.serialize(includeSignature: false);
    txn.userSignature = Rsa.sign(key.privateKey, serializedWithoutSigs);
    if (_appKey != null) {
      txn.appSignature = Rsa.sign(_appKey!, serializedWithoutSigs);
    }
    txn.id = Digest("SHA3-256").process(txn.serialize());
    _repository.save(txn);
    return txn;
  }

  /// Commits a [TransactionModel] by persisting its [TransactionModel.block]
  /// and [TransactionModel.merkelProof] values.
  void commit(
      Uint8List transactionId, BlockModel block, Uint8List merkelProof) {
    _repository.commit(transactionId, block, merkelProof);
  }

  void tryAdd(TransactionModel transaction) {
    if (transaction.id != null) {
      TransactionModel? found = _repository.getById(transaction.id!);
      if (found == null) {
        _repository.save(transaction);
      }
    }
  }

  /// Validates the [TransactionModel] inclusion in [TransactionModel.block] by
  /// validating its [TransactionModel.merkelProof] with [MerkelTree.validate].
  static bool validateInclusion(TransactionModel transaction, Uint8List root) =>
      MerkelTree.validate(transaction.id!, transaction.merkelProof!, root);

  /// Validates the [TransactionModel] integrity by rebuilding its hash [TransactionModel.id].
  static bool validateIntegrity(TransactionModel transaction) =>
      Bytes.memEquals(
          Digest("SHA3-256").process(transaction.serialize()), transaction.id!);

  /// Validates the author of the [TransactionModel] by calling [Rsa.verify] with
  /// its [TransactionModel.userSignature].
  static bool validateAuthor(
          TransactionModel transaction, RsaPublicKey pubKey) =>
      Rsa.verify(pubKey, transaction.serialize(includeSignature: false),
          transaction.userSignature!);

  /// Gets all the transactions from a [BlockModel] by its [BlockModel.id].
  List<TransactionModel> getByBlock(Uint8List id) =>
      _repository.getByBlockId(id);

  /// Gets all the transactions that were not committed by [commit].
  List<TransactionModel> getPending() => _repository.getByBlockId(null);
}
