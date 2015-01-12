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

library dartuino.usart;

import 'package:logging/logging.dart';

import 'interrupt_manager.dart';
import '../misc/util.dart';
import '../../mcu.dart';
//import 'dart:io';

/**
 * USART implementation
 */
class Usart0 {

  static final Logger log = new Logger('dartuino.timer.Usart0');

  static const UDR0_ADDRESS = 0xC6;

  static const UCSR0A_ADDRESS = 0xC0;

  static const MPCM0 = 0;
  static const U2X0 = 1;
  static const UPE0 = 2;
  static const DOR0 = 3;
  static const FE0 = 4;
  static const UDRE0 = 5;
  static const TXC0 = 6;
  static const RXC0 = 7;

  static const UCSR0B_ADDRESS = 0xC1;

  static const TXB80 = 0;
  static const RXB80 = 1;
  static const UCSZ02 = 2;
  static const TXEN0 = 3;
  static const RXEN0 = 4;
  static const UDRIE0 = 5;
  static const TXCIE0 = 6;
  static const RXCIE0 = 7;

  static const UCSR0C_ADDRESS = 0xC2;

  static const UCPOL0 = 0;
  static const UCSZ00 = 1;
  static const UCPHA0 = 1;
  static const UCSZ01 = 2;
  static const UDORD0 = 2;
  static const USBS0 = 3;
  static const UPM00 = 4;
  static const UPM01 = 5;
  static const UMSEL00 = 6;
  static const UMSEL01 = 7;

  int _ucsr0a;
  int _ucsr0b;
  int _ucsr0c;
  int _udr0;

  MCUnit mcu;

  Usart0(this.mcu) {

    log.info("Initializing Usart0");

    _ucsr0a = 0;
    _ucsr0b = 0;
    _ucsr0c = 0;
    _udr0 = 0;

    mcu.connect(UCSR0A_ADDRESS, read: (a) => ucsr0a, write: (a, v) => ucsr0a = v);
    mcu.connect(UCSR0B_ADDRESS, read: (a) => ucsr0b, write: (a, v) => ucsr0b = v);
    mcu.connect(UCSR0C_ADDRESS, read: (a) => ucsr0c, write: (a, v) => ucsr0c = v);
    mcu.connect(UDR0_ADDRESS, read: (a) => udr0, write: (a, v) => udr0 = v);

  }

  step() {

  }

  int get ucsr0a => _ucsr0a | (1 << (UDRE0));
  int get ucsr0b =>_ucsr0b;
  int get ucsr0c => _ucsr0c;

  int get udr0 {
      return 65;
  }

  void set udr0(int value) {

    _udr0 = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      log.fine("UDR0: ${_udr0.toRadixString(2).padLeft(8, '0')}");
    }

  }

  int get udre0 => getBit(_ucsr0a, UDRE0);
  set udre0(int value) => setBit(_ucsr0a, udre0, value);

  int get mpcm0 => getBit(_ucsr0a, MPCM0);

  int get txc0 => getBit(_ucsr0a, TXC0);
  set txc0(int value) => setBit(_ucsr0a, TXC0, value);

  int get rxc0 => getBit(_ucsr0a, RXC0);
  set rxc0(int value) => setBit(_ucsr0a, RXC0, value);

  int get txcie0 => getBit(_ucsr0c, TXCIE0);
  int get rxcie0 => getBit(_ucsr0b, RXCIE0);
  int get udrie0 => getBit(_ucsr0b, UDRIE0);

  void set ucsr0a(int value) {

   _ucsr0a &= ~(value & (getBit(_ucsr0a, TXC0)));
    _ucsr0a = value;

    if (log.isLoggable(Level.FINE)) {
      log.fine("UCSR0A: ${_ucsr0a.toRadixString(2).padLeft(8, '0')}");
    }

  }

  void set ucsr0b(int value) {

    _ucsr0b = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      log.fine("UCSR0B: ${_ucsr0b.toRadixString(2).padLeft(8, '0')}");
    }

  }


  void set ucsr0c(int value) {

    _ucsr0c = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      log.fine("UCSR0C: ${_ucsr0c.toRadixString(2).padLeft(8, '0')}");
    }

  }



}
