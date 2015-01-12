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
InputElement _input;
bool _ticking = false;

MCUnit mcu;
Clock clock;

void main() {

  _fileInput = document.querySelector('#files');
  _fileInput.onChange.listen((e) => _onFileInputChange());
  _input = document.querySelector('#button');
  _input.onClick.listen(
      (event) {
    requestTick();
  } 
  );
  setupLog();

}

void runMcu() {

  clock = new Clock(mcu);
  //clock.addPulseListener((var clock) { log.info("teste"); } );

}

void _onFileInputChange() {

  File file = _fileInput.files[0];

  var reader = new FileReader();

  reader.onLoad.listen(loadAndRun);

  reader.readAsText(file);

}

void loadAndRun(e) {

  mcu = new MCUnit.fromHex(e.target.result.toString());

  mcu.connect(MCUnit.PORTB_ADDRESS, write: (k, v) {
    log.info('PORTB: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTC_ADDRESS, write: (k, v) {
    log.info('PORTC: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  mcu.connect(MCUnit.PORTD_ADDRESS, write: (k, v) {
    log.info('PORTD: = ' + v.toRadixString(2).padLeft(8, '0'));
  });

  const progressRate = const Duration(milliseconds: 5);

  runMcu();
  
}

void requestTick() {
  if (!_ticking) {
    window.animationFrame.then(_update);
    _ticking = true;
  }
}

void _update(num time) {
  for (int i = 0; i < 960*12; i++) {
  clock.pulse();
  }
  _ticking = false;
  requestTick();
  
  TableElement table2 = new TableElement();
   table2.style.width='100%';
   var tBody2 = table2.createTBody(); 

   tBody2.insertRow(0)..insertCell(0).text = mcu.memory[MCUnit.PORTB_ADDRESS].toRadixString(2).padLeft(8, '0')
                  ..insertCell(1).text = mcu.memory[MCUnit.PORTC_ADDRESS].toRadixString(2).padLeft(8, '0')
                  ..insertCell(2).text = mcu.memory[MCUnit.PORTD_ADDRESS].toRadixString(2).padLeft(8, '0');

   tBody2.insertRow(1)..insertCell(0).text = "0x${mcu.sp.toRadixString(16).padLeft(4, '0').toUpperCase()}"
                  ..insertCell(1).text = "0x${mcu.pc.toRadixString(16).padLeft(4, '0').toUpperCase()}";
   
   var el = document.querySelector('#debugPanel');
   el.children.clear();
     el.children.add(table2);
}

void setupLog() {

  hierarchicalLoggingEnabled = true;

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen(new LogPrintHandler(printFunc: window.console.log));

}
