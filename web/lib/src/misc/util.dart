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

library dartuino.util;
import 'package:logging/logging.dart';

final Logger log = new Logger('dartuino.util');

int setBit(int num, int bit, int value) {
  int mask = 1 << bit;
  return (num & ~mask) | (-value & mask);
}

int getBit(num, bit) => ((num >> bit) & 1);

logInstruction(var mcu, var instruction, [arg1, arg2]) {

  if (log.isLoggable(Level.FINER)) {

    String address = "0x${(((mcu.lastPc)).toRadixString(16).padLeft(4, '0')).toUpperCase()} SP: ${mcu.sp.toRadixString(16).padLeft(4, '0')}  -> Cycle: ${mcu.count}";
    String mnemonic = (instruction.mnemonic.padRight(5));

    if (arg1 == null) {
      log.finer("$address\t$mnemonic ");
    } else {
      if (arg2 == null) {
        log.finer("$address\t$mnemonic\t$arg1");
      } else {
        log.finer("$address\t$mnemonic\t$arg1, $arg2");
      }

    }
  }

}

logRegisters(var mcu) {

  if (log.isLoggable(Level.FINEST)) {

    StringBuffer r = new StringBuffer();

    for (int i = 0; i < 32; i++) {
      r.write(' R${i.toString().padLeft(2, '0')}: ${(mcu.registers[i].toRadixString(16).padLeft(2, '0'))}');
    }

    log.finest(r.toString());
    log.finest('Status: ${mcu.status.toRadixString(2).padLeft(8, '0')} (${mcu.status}) - SP: 0x${mcu.sp.toRadixString(16)} - X: ${mcu.rx}, Y: ${mcu.ry}, Z: ${mcu.rz}');

  }

}

logNotImplemented(var instruction) => log.severe('!!! ${instruction.mnemonic}: NOT IMPLEMENTED !!!');
