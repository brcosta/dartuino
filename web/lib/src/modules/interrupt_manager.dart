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

library dartuino.interrupt_manager;

import 'package:logging/logging.dart';

import '../misc/util.dart';

/**
 * Manages pending interrupts
 */
class InterruptManager {

  static final Logger log = new Logger(
      'dartuino.interrupt_manager.InterruptManager');

  static const int MAX_INTERRUPTS = 25;

  static const INT0_VECTOR = 1; // External Interrupt Request 0
  static const INT1_VECTOR = 2; // External Interrupt Request 1
  static const PCINT0_VECTOR = 3; // Pin Change Interrupt Request 0
  static const PCINT1_VECTOR = 4; // Pin Change Interrupt Request 0
  static const PCINT2_VECTOR = 5; // Pin Change Interrupt Request 1
  static const WDT_VECTOR = 6; // Watchdog Time-out Interrupt
  static const TIMER2_COMPA_VECTOR = 7; // Timer/Counter2 Compare Match A
  static const TIMER2_COMPB_VECTOR = 8; // Timer/Counter2 Compare Match A
  static const TIMER2_OVF_VECTOR = 9; // Timer/Counter2 Overflow
  static const TIMER1_CAPT_VECTOR = 10; // Timer/Counter1 Capture Event
  static const TIMER1_COMPA_VECTOR = 11; // Timer/Counter1 Compare Match A
  static const TIMER1_COMPB_VECTOR = 12; // Timer/Counter1 Compare Match B
  static const TIMER1_OVF_VECTOR = 13; // Timer/Counter1 Overflow
  static const TIMER0_COMPA_VECTOR = 14; // TimerCounter0 Compare Match A
  static const TIMER0_COMPB_VECTOR = 15; // TimerCounter0 Compare Match B
  static const TIMER0_OVF_VECTOR = 16; // Timer/Couner0 Overflow
  static const SPI_STC_VECTOR = 17; // SPI Serial Transfer Complete
  static const USART_RX_VECTOR = 18; // USART Rx Complete
  static const USART_UDRE_VECTOR = 19; // USART, Data Register Empty
  static const USART_TX_VECTOR = 20; // USART Tx Complete
  static const ADC_VECTOR = 21; // ADC Conversion Complete
  static const EE_READY_VECTOR = 22; // EEPROM Ready
  static const ANALOG_COMP_VECTOR = 23; // Analog Comparator
  static const TWI_VECTOR = 24; // Two-wire Serial Interface
  static const SPM_READY_VECTOR = 25; // Store Program Memory Read

  int _pendingInterrupts;

  InterruptManager() {

    if (log.isLoggable(Level.INFO)) {
      log.info('Initializing interrupt manager');
    }

    _pendingInterrupts = 0;

  }

  void registerPending(int vector) {

    if (log.isLoggable(Level.FINEST)) {
      log.finest('Registering pending interrupt at ${vector}');
    }

    _pendingInterrupts = setBit(_pendingInterrupts, vector, 1);

  }

  void unregisterPending(int vector) {

    if (log.isLoggable(Level.FINEST)) {
      log.finest('Unregistering pending interrupt at ${vector}');
    }

    _pendingInterrupts = setBit(_pendingInterrupts, vector, 0);

  }

  int get firstPendingInterrupt {

    if (_pendingInterrupts == 0) {
      return -1;
    }

    for (int i = 1; i <= MAX_INTERRUPTS; i++) {
      if (getBit(_pendingInterrupts, i) == 1) {
        return i;
      }
    }

    return -1;

  }

}
