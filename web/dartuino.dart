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

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import 'lib/mcu.dart';

import 'lib/clock.dart';
import 'lib/src/modules/timer.dart';

final Logger log = new Logger('main');

InputElement _fileInput;

MCUnit mcu;
Timer0 timer0;

void main() {

  _fileInput = document.querySelector('#files');
  _fileInput.onChange.listen((e) => _onFileInputChange());

  setupLog();
  hierarchicalLoggingEnabled = true;

  initializeInstructions();
  initializeInstructionsLookup();

}

void runMcu() {

  log.info("Starting MCU Clock");
  Clock clock = new Clock();

  mcu.clock = clock;
  log.info("-- Running --");
  clock.run();

}

void _onFileInputChange() {

  File file = _fileInput.files[0];

  var reader = new FileReader();

  reader.onLoad.listen(loadAndRun);

  reader.readAsText(file);

}

void loadAndRun(e) {

  mcu = new MCUnit.fromHex(e.target.result.toString());

  mcu.connect(MCUnit.PORTB_ADDRESS, writeListener: (k, v) {
    log.info('PORTB: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTC_ADDRESS, writeListener: (k, v) {
    log.info('PORTC: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTD_ADDRESS, writeListener: (k, v) {
    log.info('PORTD: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  const progressRate = const Duration(milliseconds: 5);

  runMcu();

}

void setupLog() {

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(new LogPrintHandler(printFunc: window.console.log)
      );

}
