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

import 'package:quiver/iterables.dart';
import 'package:logging/logging.dart';

/**
 * Manages pending interrupts
 */
class InterruptManager {

  static final Logger log = new Logger('dartuino.interrupt_manager.InterruptManager');

  static const int MAX_INTERRUPTS = 0x32 ~/ 2;

  static const INT0_VECTOR = 1 * 2; // External Interrupt Request 0
  static const INT1_VECTOR = 2 * 2; // External Interrupt Request 1
  static const PCINT0_VECTOR = 3 * 2; // Pin Change Interrupt Request 0
  static const PCINT1_VECTOR = 4 * 2; // Pin Change Interrupt Request 0
  static const PCINT2_VECTOR = 5 * 2; // Pin Change Interrupt Request 1
  static const WDT_VECTOR = 6 * 2; // Watchdog Time-out Interrupt
  static const TIMER2_COMPA_VECTOR = 7 * 2; // Timer/Counter2 Compare Match A
  static const TIMER2_COMPB_VECTOR = 8 * 2; // Timer/Counter2 Compare Match A
  static const TIMER2_OVF_VECTOR = 9 * 2; // Timer/Counter2 Overflow
  static const TIMER1_CAPT_VECTOR = 10 * 2; // Timer/Counter1 Capture Event
  static const TIMER1_COMPA_VECTOR = 11 * 2; // Timer/Counter1 Compare Match A
  static const TIMER1_COMPB_VECTOR = 12 * 2; // Timer/Counter1 Compare Match B
  static const TIMER1_OVF_VECTOR = 13 * 2; // Timer/Counter1 Overflow
  static const TIMER0_COMPA_VECTOR = 14 * 2; // TimerCounter0 Compare Match A
  static const TIMER0_COMPB_VECTOR = 15 * 2; // TimerCounter0 Compare Match B
  static const TIMER0_OVF_VECTOR = 16 * 2; // Timer/Couner0 Overflow
  static const SPI_STC_VECTOR = 17 * 2; // SPI Serial Transfer Complete
  static const USART_RX_VECTOR = 18 * 2; // USART Rx Complete
  static const USART_UDRE_VECTOR = 19 * 2; // USART, Data Register Empty
  static const USART_TX_VECTOR = 20 * 2; // USART Tx Complete
  static const ADC_VECTOR = 21 * 2; // ADC Conversion Complete
  static const EE_READY_VECTOR = 22 * 2; // EEPROM Ready
  static const ANALOG_COMP_VECTOR = 23 * 2; // Analog Comparator
  static const TWI_VECTOR = 24 * 2; // Two-wire Serial Interface
  static const SPM_READY_VECTOR = 25 * 2  ; // Store Program Memory Read

  List<bool> _pendingInterrupts;

  InterruptManager() {

    if (log.isLoggable(Level.INFO)) {
      log.info('Initializing interrupt manager');
    }

    _pendingInterrupts = new List();

    for (int i in range(MAX_INTERRUPTS)) {
      pendingInterrupts.add(false);
    }

  }

  void registerPending(int vector) {

    if (log.isLoggable(Level.FINEST)) {
      log.finest('Registering pending interrupt at ${(vector ~/ 2)}');
    }

    pendingInterrupts[(vector ~/ 2)] = true;

  }

  void unregisterPending(int vector) {

    if (log.isLoggable(Level.FINEST)) {
      log.finest('Unregistering pending interrupt at ${(vector ~/ 2)}');
    }

    pendingInterrupts[(vector ~/ 2)] = false;

  }

  List<bool> get pendingInterrupts => _pendingInterrupts;

}