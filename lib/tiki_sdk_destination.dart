/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */
import 'dart:convert';
import 'dart:typed_data';

import 'utils/compact_size.dart';

/// The destination to which the data is consented to be used.
class TikiSdkDestination {
  /// An optional list of application specific uses cases
  /// applicable to the given destination. Prefix with NOT
  /// to invert. _i.e. NOT ads
  final List<String> uses;

  /// A list of paths, preferably URL without the scheme or
  /// reverse FQDN. Keep list short and use wildcard (*)
  /// matching. Prefix with NOT to invert.
  /// _i.e. NOT mytiki.com/*
  final List<String> paths;

  /// Builds a destination with [paths] and [uses].
  const TikiSdkDestination(this.paths, {this.uses = const ["*"]});

  /// Builds a destination for all [paths] and [uses]
  const TikiSdkDestination.all()
      : paths = const ['*'],
        uses = const ['*'];

  /// Builds a destination with no [paths] nor [uses].
  ///
  /// This should be use to revoke all destinations for a specific origin.
  const TikiSdkDestination.none()
      : paths = const [],
        uses = const [];

  /// Converts the json representation of the destination into its object.
  static TikiSdkDestination fromJson(String jsonString) =>
      TikiSdkDestination.fromMap(jsonDecode(jsonString));

  TikiSdkDestination.fromMap(Map map)
      : uses = map['uses'] == null ? [] : [...map['uses']],
        paths = [...map['paths']];

  @override
  String toString() => jsonEncode({'uses': uses, 'paths': paths});

  /// Serializes the destination as a byte array to be used in the blockchain.
  Uint8List serialize() {
    return (BytesBuilder()
          ..add(CompactSize.encode(
              Uint8List.fromList(jsonEncode(paths).codeUnits)))
          ..add(CompactSize.encode(
              Uint8List.fromList(jsonEncode(uses).codeUnits))))
        .toBytes();
  }

  /// Deserializes a byte array into a destination.
  static TikiSdkDestination deserialize(Uint8List serialized) {
    List<Uint8List> unserialized = CompactSize.decode(serialized);
    List<dynamic> paths = jsonDecode(String.fromCharCodes(unserialized[0]));
    List<dynamic> uses = jsonDecode(String.fromCharCodes(unserialized[1]));
    return TikiSdkDestination(
      paths.map<String>((e) => e.toString()).toList(), 
      uses: uses.map<String>((e) => e.toString()).toList());
  }

  String toJson() => toString();
}
