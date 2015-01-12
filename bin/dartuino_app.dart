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
import 'package:logging_handlers/server_logging_handlers.dart';

import '../web/lib/mcu.dart';
import '../web/lib/clock.dart';

final Logger log = new Logger('main');

MCUnit mcu;

void main() {

  setupLog();

  runMcu();

}

void runMcu() {

  File file = new File("Blink.cpp.hex");

  mcu = new MCUnit.fromHex(file.readAsStringSync());

  mcu.connect(MCUnit.PORTB_ADDRESS, write: (k, v) {
    log.info('PORTB: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  Clock clock = new Clock(mcu);
  clock.run();

}

void setupLog() {
  
  hierarchicalLoggingEnabled = true;

  Logger.root.level = Level.FINE;
  //Logger.root.level = Level.FINEST;

  Logger.root.onRecord.listen(new LogPrintHandler(printFunc: print));
  //Logger.root.onRecord.listen(new SyncFileLoggingHandler("/home/bruno/log.txt"));

}
