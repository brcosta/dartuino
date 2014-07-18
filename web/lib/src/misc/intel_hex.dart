// Copyright 2014 Dartuino authors. Please see AUTHORS.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dartuino.intel_hex;

import 'dart:typed_data';

const DATA = 0;

/**
 * Reads an Intel Hex file into a [Uint8List].
 */
Uint8List parseIntelHex(String data) {

  var program = new Uint8List(32768);
  var pos = 0;

  while (pos + 1 <= data.length) {

    pos++;
    var dataLength = int.parse(data.substring(pos, pos + 2), radix: 16);

    pos += 2;

    var address = int.parse(data.substring(pos, pos + 4), radix: 16);
    pos += 4;

    var recordType = int.parse(data.substring(pos, pos + 2), radix: 16);
    pos += 2;

    if (recordType == DATA) {

      for (var i = 0; i < dataLength; i++) {
        program[address + i] = int.parse(data[pos + i * 2] + data[pos + ((i * 2) + 1)], radix: 16);
      }

    }

    pos += dataLength * 2 + 2;

    if (data[pos] == "\r") pos++;

    if (data[pos] == "\n") pos++;

  }

  return program;

}
