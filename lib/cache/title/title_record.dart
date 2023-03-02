/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */

import 'dart:convert';
import 'dart:typed_data';

import '../../utils/bytes.dart';
import '../../utils/compact_size.dart';
import 'title_repository.dart';
import 'title_tag.dart';

/// Describes an asset and contains a Pointer Record [ptr] to
/// the actual asset.
class TitleRecord {
  /// A Pointer Record identifying the asset
  String ptr;

  /// The origin from which the data was generated.
  String origin;

  /// The transaction id of this record.
  Uint8List? transactionId;

  /// A human-readable description of the asset.
  String? description;

  /// A list of search-friendly tags describing the data.
  List<TitleTag> tags;

  TitleRecord(
    this.origin,
    this.ptr, {
    this.transactionId,
    this.tags = const [],
    this.description,
  });

  /// Construct a [TitleRecord] from a [map].
  ///
  /// Primary use is [ModelRepository] object marshalling.
  TitleRecord.fromMap(Map<String, dynamic> map)
      : ptr = map[TitleRepository.columnPtr],
        origin = map[TitleRepository.columnOrigin],
        description = map[TitleRepository.columnDescription],
        transactionId = map[TitleRepository.columnTransactionId],
        tags = map[TitleRepository.columnTags] != null
            ? map[TitleRepository.columnTags]
                .map<TitleTag>((tag) => TitleTag.from(tag))
                .toList()
            : [];

  /// Converts this to Map
  Map toMap() => {
        TitleRepository.columnPtr: ptr,
        TitleRepository.columnOrigin: origin,
        TitleRepository.columnDescription: description,
        TitleRepository.columnTags:
            tags.map<String>((tag) => tag.value).toList(),
        TitleRepository.columnTransactionId: transactionId
      };

  /// Serializes this to binary.
  ///
  /// Primary use is on-chain storage. The [transaction_id] is not represented
  /// in the serialized output.
  Uint8List serialize() {
    String jsonTags = jsonEncode(tags.map((tag) => tag.value).toList());
    return (BytesBuilder()
          ..add(CompactSize.encode(Bytes.utf8Encode(ptr)))
          ..add(CompactSize.encode(Bytes.utf8Encode(origin)))
          ..add(description == null
              ? Uint8List(1)
              : CompactSize.encode(Bytes.utf8Encode(description!)))
          ..add(CompactSize.encode(Bytes.utf8Encode(jsonTags))))
        .toBytes();
  }

  /// Construct a new [TitleRecord] from binary data.
  ///
  /// See [serialize] for supported binary format.
  factory TitleRecord.deserialize(Uint8List serialized) =>
      TitleRecord.decode(CompactSize.decode(serialized));

  /// Construct a new [TitleRecord] from decoded binary data.
  ///
  /// See [serialize] for supported binary format.
  factory TitleRecord.decode(List<Uint8List> bytes) {
    return TitleRecord(Bytes.utf8Decode(bytes[1]), Bytes.utf8Decode(bytes[0]),
        description: Bytes.utf8Decode(bytes[2]),
        tags: jsonDecode(Bytes.utf8Decode(bytes[3]))
            .map<TitleTag>((tag) => TitleTag.from(tag))
            .toList());
  }
}
