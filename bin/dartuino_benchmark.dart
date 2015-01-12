import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import '../web/lib/mcu.dart';
import '../web/lib/clock.dart';


final Logger log = new Logger('main');

MCUnit mcu;
Clock clock;

class TemplateBenchmark extends BenchmarkBase {
  const TemplateBenchmark() : super("Template");

  static main() {
    new TemplateBenchmark().report();
  }

  // Not measured: setup code executed before the benchmark runs.
  void setup() {

    hierarchicalLoggingEnabled = false;

    initializeInstructions();
    initializeInstructionsLookup();

    Logger.root.level = Level.OFF;
    Logger.root.onRecord.listen(new LogPrintHandler(printFunc: print));

    File file = new File("Blink.hex");

    mcu = new MCUnit.fromHex(file.readAsStringSync());

    clock = new Clock(mcu);

  }

  // The benchmark code.
  void run() {
    for (int i = 0; i < 128000000; i++) {
      mcu.step();
      mcu.timer0.step();
    }
  }

  void warmup() {}
  void exercise() => run();
  void teardown() {}

}

main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}
