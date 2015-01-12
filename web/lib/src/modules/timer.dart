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

library dartuino.timer;

import 'package:logging/logging.dart';

import 'interrupt_manager.dart';
import '../misc/util.dart';
import '../../mcu.dart';

/**
 * Timer0 implementation:
 *   Modes supported: Fast PWM / OVF0 Interrupt.
 */
class Timer0 {

  static final Logger log = new Logger('dartuino.timer.Timer0');

  static const TIMSK0_ADDRESS = 0x6E;
  static const TCNT0_ADDRESS = 0x46;
  static const TCCR0A_ADDRESS = 0x44;
  static const TCCR0B_ADDRESS = 0x45;
  static const OCR0A_ADDRESS = 0x47;
  static const OCR0B_ADDRESS = 0x48;
  static const TIFR0_ADDRESS = 0x35;

  static const MODE_NORMAL = 0x00;
  static const MODE_PC_PWM = 0x01;
  static const MODE_CTC = 0x02;
  static const MODE_FAST_PWM = 0x03;

  static const WGM00 = 0;
  static const WGM01 = 1;
  static const WGM02 = 3;

  static const CS00 = 0;
  static const CS01 = 1;
  static const CS02 = 2;

  static const TOIE0 = 0;
  static const OCIE0A = 1;
  static const OCIE0B = 2;

  static const TOV0 = 0;
  static const OCF0A = 1;
  static const OCF0B = 2;

  static final List prescalerLookup = [0, 1, 8, 64, 256, 1024, 0, 0];

  int _timsk0;
  int _tcnt0;
  int _tccr0a;
  int _tccr0b;
  int _ocr0a;
  int _ocr0b;
  int _tifr0;

  int mode;
  int prescaler;

  int waitCycles;

  MCUnit mcu;

  Timer0(this.mcu) {

    log.info("Initializing Timer0");

    _timsk0 = 0;
    _tcnt0 = 0;
    _tccr0a = 0;
    _tccr0b = 0;
    _ocr0a = 0;
    _ocr0b = 0;
    _tifr0 = 0;

    mode = 0;
    prescaler = 0;
    waitCycles = 0;

    mcu.connect(TIMSK0_ADDRESS, read: (a) => timsk0, write: (a, v) => timsk0 = v);
    mcu.connect(TCNT0_ADDRESS, read: (a) => tcnt0, write: (a, v) => tcnt0 = v);
    mcu.connect(TCCR0A_ADDRESS, read: (a) => tccr0a, write: (a, v) => tccr0a = v);
    mcu.connect(TCCR0B_ADDRESS, read: (a) => tccr0b, write: (a, v) => tccr0b = v);
    mcu.connect(OCR0A_ADDRESS, read: (a) => ocr0a, write: (a, v) => ocr0a = v);
    mcu.connect(OCR0B_ADDRESS, read: (a) => ocr0b, write: (a, v) => ocr0b = v);

  }

  step() {

    if (waitCycles == 0) {

      var prescalerValue = prescalerLookup[prescaler];

      if (prescalerValue == 0) {
        return;
      }

      switch (mode) {

        case MODE_NORMAL:

          if (tcnt0 == 255) {
            tcnt0 = 0;
          } else {
            tcnt0++;
          }

          break;

        case MODE_PC_PWM:

          if (tcnt0 == 255) {
            tcnt0 = 0;
          } else {
            tcnt0++;
          }

          break;

        case MODE_CTC:

          break;

        case MODE_FAST_PWM:

          if (tcnt0 == 255) {

            if (toie0 == 1) {
              mcu.interruptManager.registerPending(InterruptManager.TIMER0_OVF_VECTOR);
            }

            tcnt0 = 0;

          } else {

            tcnt0++;

          }
          break;

      }

      waitCycles = prescalerValue;

    } else {

      waitCycles--;

    }

  }


  void updateTimerMode() {

    mode = wgm01 << 1 | wgm00;

    if (log.isLoggable(Level.FINE)) {
      //log.fine("Timer Mode updated: ${mode.toRadixString(2).padLeft(3, '0')}");
    }
  }

  void updatePrescaler() {

    prescaler = cs02 << 2 | cs01 << 1 | cs00;

    if (log.isLoggable(Level.FINE)) {
      //log.fine("Prescaler updated: ${prescaler.toRadixString(2).padLeft(3, '0')}");
    }

  }

  int get timsk0 => _timsk0;
  int get tcnt0 => _tcnt0;
  int get tccr0a => _tccr0a;
  int get tccr0b => _tccr0b;
  int get ocr0a => _ocr0a;
  int get ocr0b => _ocr0b;
  int get tifr0 => _tifr0;

  int get wgm00 => getBit(tccr0a, WGM00);
  int get wgm01 => getBit(tccr0a, WGM01);
  int get wgm02 => getBit(tccr0b, WGM02);

  int get cs00 => getBit(tccr0b, CS00);
  int get cs01 => getBit(tccr0b, CS01);
  int get cs02 => getBit(tccr0b, CS02);

  int get toie0 => getBit(timsk0, TOIE0);
  int get ocie0a => getBit(timsk0, OCIE0A);
  int get ocie0b => getBit(timsk0, OCIE0B);

  int get tov0 => getBit(tifr0, TOV0);
  int get ocf0a => getBit(tifr0, OCF0A);
  int get ocf0b => getBit(tifr0, OCF0B);

  void set timsk0(int value) {

    _timsk0 = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      //  log.fine("TIMSK0: ${_timsk0.toRadixString(2).padLeft(8, '0')}");
    }

  }

  void set tcnt0(int value) {
    _tcnt0 = value & 0xFF;
  }

  void set tccr0a(int value) {

    _tccr0a = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      log.fine("TCCR0A: ${_tccr0a.toRadixString(2).padLeft(8, '0')}");
    }

    updateTimerMode();

  }

  void set tccr0b(int value) {

    _tccr0b = value & 0xFF;

    if (log.isLoggable(Level.FINE)) {
      log.fine("TCCR0B: ${_tccr0b.toRadixString(2).padLeft(8, '0')}");
    }

    updatePrescaler();

  }

  void set ocr0a(int value) {
    _ocr0a = value & 0xFF;
  }

  void set ocr0b(int value) {
    _ocr0b = value & 0xFF;
  }

  void set tifr0(int value) {

    _tifr0 = value & 0xFF;

    if (log.isLoggable(Level.FINER)) {
      log.fine("TIFR0: ${_tifr0.toRadixString(2).padLeft(8, '0')}");
    }

  }

}
