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
  static const int INTERRUPT_TIMER0_OVF = 0x20;

  List<bool> _pendingInterrupts;

  InterruptManager() {

    if (log.isLoggable(Level.INFO)) {
      log.finest('Initializing interrupt manager');
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