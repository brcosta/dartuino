import 'dart:html';
import 'package:polymer/polymer.dart';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import 'lib/mcu.dart';
import 'lib/clock.dart';

@CustomTag('arduino-debug')
class ArduinoDebug extends PolymerElement {
  final Logger log = new Logger('main.ArduinoDebug');
    
  @observable String portB = '00000000';
  @observable String portC = '00000000';
  @observable String portD = '00000000';

  @observable String pc;
  @observable String sp;
  @observable String status;
  @observable String cycles;
  
  @observable String c;
  @observable String z;
  @observable String n;
  @observable String v;
  @observable String s;
  @observable String h;
  @observable String t;
  @observable String i;
  @observable List<int> registers;
     
  bool _ticking = false;

  MCUnit mcu;
  Clock clock;

  InputElement _fileInput;
  ButtonElement _input;
      
  ArduinoDebug.created() : super.created();
  
  @override
  void attached() {
    super.attached();
    _fileInput = $['files'];
    _fileInput.onChange.listen((e) => _onFileInputChange());
    
    _input = $['button'];
    registers = new List();
  }
  
  @override
  void detached() {
    super.detached();

  }
  
 
  void runMcu() {

    clock = new Clock(mcu);

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
      portB = v.toRadixString(2).padLeft(8, '0');
    });

    mcu.connect(MCUnit.PORTC_ADDRESS, write: (k, v) {
      log.info('PORTC: = ' + v.toRadixString(2).padLeft(8, '0'));
      portC = v.toRadixString(2).padLeft(8, '0');
    });

    mcu.connect(MCUnit.PORTD_ADDRESS, write: (k, v) {
      log.info('PORTD: = ' + v.toRadixString(2).padLeft(8, '0'));
      portD = v.toRadixString(2).padLeft(8, '0');
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
    for (int i = 0; i < 960*15; i++) {
    clock.pulse();
    }
    _ticking = false;
    requestTick();
       
    pc = "0x${mcu.pc.toRadixString(16).toUpperCase().padLeft(4, '0')}";
    sp = "0x${mcu.sp.toRadixString(16).toUpperCase().padLeft(4, '0')}";
    cycles= "${mcu.cycles}";
    status = "0x${mcu.sp.toRadixString(2).padLeft(8, '0')}";

    c = "${mcu.c}";
    z = "${mcu.z}";
    n = "${mcu.n}";
    v = "${mcu.v}";
    s = "${mcu.s}";
    h = "${mcu.h}";
    t = "${mcu.t}";
    i = "${mcu.i}";
    
  }
  
  void setupLog() {

    hierarchicalLoggingEnabled = true;

    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen(new LogPrintHandler(printFunc: window.console.log));

  }

  
}
