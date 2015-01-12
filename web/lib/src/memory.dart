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

library dartuino.mcu.memory;

import 'dart:typed_data';


/**
 * Byte addresseable memory module.
 */
class Memory {

  Map _readListeners;
  Map _writeListeners;

  Uint8List _memory;

  Memory(this._memory) {
    _readListeners = new Map<int, dynamic>();
    _writeListeners = new Map<int, dynamic>();
  }

  void connect(address, {read, write}) {
    if (read != null) {
      _readListeners[address] = read;
    }

    if (write != null) {
      _writeListeners[address] = write;
    }
  }

  void operator []=(int address, int value) {

    if (_writeListeners.containsKey(address)) {
        _writeListeners[address](address, value & 0xFF);
    }

    _memory[address] = value & 0xFF;

  }

  int operator [](int address) {

    if (_readListeners.containsKey(address) && _readListeners[address](address) != null) {
      return _readListeners[address](address) & 0xFF;
    }

    return _memory[address];

  }

  void write(int address, int value) {
    _memory[address] = value;
  }

  int readWord(int i) => (this[i + 1] << 8) | this[i];

  void writeWord(int i, int value) {
    this[i + 1] = (value & 0xFF00) >> 8;
    this[i] = value & 0xFF;
  }

}
