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

library dartuino.mcu.registers;

import 'dart:typed_data';


/**
 * Byte addresseable registers module.
 */
class Registers {

  Uint8List _registersFile;

  Registers(this._registersFile);

  void operator []=(int r, int value) {
    _registersFile[r] = value & 0xFF;
  }

  int operator [](int r) {

    return _registersFile[r];
  }

  int readWord(int r) {
    return (_registersFile[r + 1] << 8) | _registersFile[r];
  }

  void writeWord(int r, int value) {
    _registersFile[r + 1] = (value & 0xFF00) >> 8;
    _registersFile[r] = value & 0xFF;
  }

}
