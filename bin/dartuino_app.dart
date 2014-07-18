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

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import '../web/lib/mcu.dart';
import '../web/lib/clock.dart';

final Logger log = new Logger('main');

MCUnit mcu;

void main() {

  setupLog();
  hierarchicalLoggingEnabled = true;

  initializeInstructions();
  initializeInstructionsLookup();

  runMcu();

}

void runMcu() {

  File file = new File("DigitalReadSerial.cpp.hex");

  mcu = new MCUnit.fromHex(file.readAsStringSync());

  mcu.connect(MCUnit.PORTB_ADDRESS, writeListener: (k, v) {
    log.info('PORTB: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTC_ADDRESS, writeListener: (k, v) {
    log.info('PORTC: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTD_ADDRESS, writeListener: (k, v) {
    log.info('PORTD: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  Clock clock = new Clock();
  mcu.clock = clock;

  log.info("---- Running ----");
  clock.run();

}

void setupLog() {

  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen(new LogPrintHandler(printFunc: print));

}
