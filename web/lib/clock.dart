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

library dartuino.clock;

import 'package:logging/logging.dart';

/**
 * Simple implementation of a Clock source
 */
class Clock {

  static final Logger log = new Logger('dartuino.clock.Clock');

  List _devices;

  Clock() {
    log.fine("Initializing Clock");
    _devices = new List();
  }

  void run() {
    for (;;) {
      _pulse();
    }
  }

  void register(device) {

    if (log.isLoggable(Level.FINER)) {
      log.finer("Registering device: ${device.toString()}");
    }

    _devices.add(device);

  }

  void _pulse() {
    _devices.forEach((device) => device.step());
  }


}