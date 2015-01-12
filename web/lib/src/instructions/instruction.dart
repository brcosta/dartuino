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

part of dartuino.mcu;

/**
 * Instruction abstract class.
 */
abstract class Instruction {

  static final Logger log = new Logger('dartuino.instruction.Instruction');

  String mnemonic;
  String opcode;
  int mask;
  int discriminator;
  int opcodeSize;
  int cycles;

  Instruction(opcode, {opcodeSize: 1, cycles: 1}) {

    ClassMirror cm = reflectType(this.runtimeType);
    Symbol symbol = cm.simpleName;

    this.mnemonic = MirrorSystem.getName(symbol);
    this.opcode = opcode;
    this.mask = int.parse(opcode.replaceAll(new RegExp(r'\d'), "1").replaceAll(
        new RegExp(r'[^\d]'), "0"), radix: 2);
    this.discriminator = int.parse(opcode.replaceAll(new RegExp(r'[^\d]'), "0"),
        radix: 2);
    this.opcodeSize = opcodeSize;
    this.cycles = cycles;

  }

  int execute(MCUnit mcu, int opcode);

  /**
   * Extracts a variable given a value and a mask
   */
  int variableValue(mask, value) {

    var result = 0;

    switch (mask) {
      case 0x020F:
        result = (value & 0x0F) | ((value >> 5) & 0x10);
        break;
      case 0x03F8:
        result = (value >> 3) & 0x7F;
        break;
      case 0x01F1:
        result = (value & 0x01) | ((value >> 3) & 0x3E);
        break;
      case 0x00F8:
        result = ((value >> 3) & 0x1F);
        break;
      case 0x2C07:
        result = (value & 0x07) | ((value >> 7) & 0x18) | ((value >> 8) & 0x20);
        break;
      case 0x060F:
        result = (value & 0x0F) | ((value >> 5) & 0x30);
        break;
      case 0x01F0:
        result = (value & 0x01F0) >> 4;
        break;
      case 0x00CF:
        result = (value & 0x0F) | ((value >> 2) & 0x30);
        break;
      case 0x0F0F:
        result = ((value & 0x0F00) >> 4) | (value & 0x000F);
        break;
      case 0x0070:
        result = (value & 0x0070) >> 4;
        break;
      case 0x0030:
        result = (value & 0x0030) >> 4;
        break;
      case 0x0007:
        result = value & 0x0007;
        break;
      case 0x00F0:
        result = (value & 0x00F0) >> 4;
        break;
      case 0x000F:
        result = value & 0x000F;
        break;
      case 0x0FFF:
        result = value & 0x0FFF;
        break;
      default:
        for (var i = 16; i >= 0; i--) {
          if (((mask >> i & 1) == 1)) {
            result = (result << 1) | (value >> i & 1);
          }
        }
    }

    return result;

  }

  int isZero(int value) => value == 0 ? 1 : 0;
  int boolToInt(bool value) => value ? 1 : 0;

  void pushPC(MCUnit mcu) {
    mcu.memory[mcu.sp--] = mcu.pc >> 8;
    mcu.memory[mcu.sp--] = mcu.pc & 0xff;
  }

}

class ADC extends Instruction {

  ADC() : super('000111rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rd = mcu.registers[d];
    var rr = mcu.registers[r];

    var result = rd + rr + mcu.c;
    var carry = (rd & rr) | (rr & ~result) | (~result & rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & rr & ~result) | (~rd & ~rr & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class ADD extends Instruction {

  ADD() : super('000011rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rd = mcu.registers[d];
    var rr = mcu.registers[r];

    var result = rd + rr;
    var carry = (rd & rr) | (rr & ~result) | (~result & rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & rr & ~result) | (~rd & ~rr & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class ADIW extends Instruction {

  ADIW() : super('10010110KKddKKKK', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x00CF, opcode); // 0000000011001111
    int d = variableValue(0x0030, opcode); // 0000000000110000

    d = d * 2 + 24;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d', K);
    }

    var rdw = mcu.registers.readWord(d);
    var result = rdw + K;

    mcu.v = getBit(~rdw & result, 15);
    mcu.n = getBit(result, 15);
    mcu.z = isZero(result);
    mcu.c = getBit(~result & rdw, 15);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers.writeWord(d, result);

    return cycles;

  }

}

class AND extends Instruction {

  AND() : super('001000rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rd = mcu.registers[d];
    var result = rd & mcu.registers[r];

    mcu.v = 0;
    mcu.n = getBit(result, 7);
    mcu.s = mcu.n;
    mcu.z = isZero(result);

    mcu.registers[d] = result;

    return cycles;

  }

}

class ANDI extends Instruction {

  ANDI() : super('0111KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, 'R$d');
    }

    var result = mcu.registers[d] & K;

    mcu.n = getBit(result, 7);
    mcu.v = 0;
    mcu.s = mcu.n;
    mcu.z = isZero(result);

    mcu.registers[d] = result;

    return cycles;

  }

}

class ASR extends Instruction {

  ASR() : super('1001010ddddd0101');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    int rd = mcu.registers[d];

    mcu.c = getBit(rd, 1);
    rd = (rd >> 1) & 0xFF;

    mcu.n = getBit(rd, 7);
    mcu.v = mcu.n ^ mcu.c;
    mcu.s = mcu.n ^ mcu.v;
    mcu.z = boolToInt(rd == 0);

    return cycles;

  }

}

class BCLR extends Instruction {

  BCLR() : super('100101001sss1000');

  int execute(MCUnit mcu, int opcode) {

    int s = variableValue(0x0070, opcode); // 0000000001110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, s);
    }

    mcu.status = setBit(mcu.status, s, 0);

    return cycles;

  }

}

class BLD extends Instruction {

  BLD() : super('1111100ddddd0bbb');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d", b);
    }

    mcu.registers[d] = setBit(mcu.registers[d], b, mcu.t);

    return cycles;

  }

}

class BRBC extends Instruction {

  BRBC() : super('111101kkkkkkksss');

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x03F8, opcode); // 0000001111111000
    int s = variableValue(0x0007, opcode); // 0000000000000111

    var k1 = (getBit(k, 6) != 0) ? (-((~k + 1) & 0x3F)) : k;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, k1, s);
    }

    if (getBit(mcu.status, s) == 0) {
      mcu.pc += k1;
      return cycles + 1;
    }

    return cycles;

  }

}

class BRBS extends Instruction {

  BRBS() : super('111100kkkkkkksss');

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x03F8, opcode); // 0000001111111000
    int s = variableValue(0x0007, opcode); // 0000000000000111

    var k1 = (getBit(k, 6) != 0) ? (-((~k + 1) & 0x3F)) : k;
    //var k1 = (((k << 1)  & 0xFF) >> 1) & 0xFF;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, k1, s);
    }

    if (getBit(mcu.status, s) == 1) {
      mcu.pc = mcu.pc + k1;
      return cycles + 1;
    }

    return cycles;

  }

}

class BREAK extends Instruction {

  BREAK() : super('1001010110011000');

  int execute(MCUnit mcu, int opcode) {


    logNotImplemented(this);

    return cycles;

  }

}

class BSET extends Instruction {

  BSET() : super('100101000sss1000');

  int execute(MCUnit mcu, int opcode) {

    int s = variableValue(0x0070, opcode); // 0000000001110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, s);
    }

    mcu.status = setBit(mcu.status, s, 1);

    return cycles;

  }

}

class BST extends Instruction {

  BST() : super('1111101ddddd0bbb');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d", b);
    }

    mcu.t = getBit(mcu.registers[d], b);

    return cycles;

  }

}

class CALL extends Instruction {

  CALL() : super('1001010kkkkk111k', opcodeSize: 2, cycles: 4);

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x01F1, opcode); // 0000000111110001
    k = k << 16 | mcu.program[mcu.pc++];

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, k);
    }

    pushPC(mcu);
    mcu.pc = k;

    return cycles;

  }

}

class CBI extends Instruction {

  CBI() : super('10011000AAAAAbbb', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x00F8, opcode); // 0000000011111000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}: ${mcu.memory[A]}', b
          );
    }

    mcu.memory[A] = setBit(mcu.memory[A], b, 0);

    return cycles;

  }

}

class COM extends Instruction {

  COM() : super('1001010ddddd0000');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    var rd = ~mcu.registers[d];

    mcu.v = 0;
    mcu.n = getBit(rd, 7);
    mcu.z = isZero(rd);
    mcu.c = 1;

    mcu.s = mcu.n;

    mcu.registers[d] = rd;

    return cycles;

  }

}

class CP extends Instruction {

  CP() : super('000101rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rd - rr;
    var carry = (~rd & rr) | (rr & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~rr & ~result) | (~rd & rr & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    return cycles;

  }

}

class CPC extends Instruction {

  CPC() : super('000001rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = (rd - rr - mcu.c) & 0xFF;
    var carry = (~rd & rr) | (rr & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~rr & ~result) | (~rd & rr & result)), 7);
    mcu.n = getBit(result, 7);

    mcu.s = mcu.n ^ mcu.v;

    if (result != 0) {
      mcu.z = 0;
    }


    return cycles;

  }

}

class CPI extends Instruction {

  CPI() : super('0011KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    d = d + 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, 'R$d');
    }

    var rd = mcu.registers[d];

    var result = (rd - K) & 0xFF;
    var carry = (~rd & K) | (K & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~K & ~result) | (~rd & K & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    return cycles;

  }

}

class CPSE extends Instruction {

  CPSE() : super('000100rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    var rd = mcu.registers[d];
    var rr = mcu.registers[r];

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }
    
    if (rr == rd) {
      int opcodeSize = mcu.getCurrentInstruction().opcodeSize;
       mcu.pc += opcodeSize;
       return cycles + opcodeSize;
    }

    return cycles;

  }

}

class DEC extends Instruction {

  DEC() : super('1001010ddddd1010');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    var rd = --mcu.registers[d];

    mcu.n = getBit(rd, 7);
    mcu.v = boolToInt(rd == 127);
    mcu.z = isZero(mcu.registers[d]);

    mcu.s = mcu.n ^ mcu.v;

    return cycles;

  }

}

class DES extends Instruction {

  DES() : super('10010100KKKK1011');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x00F0, opcode); // 0000000011110000

    logNotImplemented(this);

    return cycles;

  }

}

class EICALL extends Instruction {

  EICALL() : super('1001010100011001');

  int execute(MCUnit mcu, int opcode) {


    logNotImplemented(this);

    return cycles;

  }

}

class EIJMP extends Instruction {

  EIJMP() : super('1001010000011001');

  int execute(MCUnit mcu, int opcode) {


    logNotImplemented(this);

    return cycles;

  }

}

class ELPM_1 extends Instruction {

  ELPM_1() : super('1001010111011000', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    mcu.registers[0] = mcu.flash[mcu.rz];

    return cycles;

  }

}

class ELPM_2 extends Instruction {

  ELPM_2() : super('1001000ddddd0110');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    logNotImplemented(this);

    return cycles;

  }

}

class ELPM_3 extends Instruction {

  ELPM_3() : super('1001000ddddd0111');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    logNotImplemented(this);

    return cycles;

  }

}

class EOR extends Instruction {

  EOR() : super('001001rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rd = mcu.registers[d];
    var rr = mcu.registers[r];

    var result = rd ^ rr;
    mcu.registers[d] = result;

    mcu.n = getBit(result, 7);
    mcu.v = 0;
    mcu.s = mcu.n;
    mcu.z = isZero(result);

    return cycles;

  }

}

class FMUL extends Instruction {

  FMUL() : super('000000110ddd1rrr');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x0070, opcode); // 0000000001110000
    int r = variableValue(0x0007, opcode); // 0000000000000111

    logNotImplemented(this);

    return cycles;

  }

}

class FMULS extends Instruction {

  FMULS() : super('000000111ddd0rrr');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x0070, opcode); // 0000000001110000
    int r = variableValue(0x0007, opcode); // 0000000000000111

    logNotImplemented(this);

    return cycles;

  }

}

class FMULSU extends Instruction {

  FMULSU() : super('000000111ddd1rrr');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x0070, opcode); // 0000000001110000
    int r = variableValue(0x0007, opcode); // 0000000000000111

    logNotImplemented(this);

    return cycles;

  }

}

class ICALL extends Instruction {

  ICALL() : super('1001010100001001', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    pushPC(mcu);
    mcu.pc = mcu.rz;

    return cycles;

  }

}

class IJMP extends Instruction {

  IJMP() : super('1001010000001001', cycles: 2);

  int execute(MCUnit mcu, int opcode) {


    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    mcu.pc = mcu.rz;

    return cycles;

  }

}

class IN extends Instruction {

  IN() : super('10110AAdddddAAAA');

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x060F, opcode); // 0000011000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}: ${mcu.memory[A]}',
          'R$d');
    }

    mcu.registers[d] = mcu.memory[A];

    return cycles;

  }

}

class INC extends Instruction {

  INC() : super('1001010ddddd0011');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    var rd = mcu.registers[d];

    rd++;

    mcu.v = boolToInt(rd == 0x80);
    mcu.n = getBit(rd, 7);
    mcu.s = mcu.n ^ mcu.v;
    mcu.z = boolToInt(rd == 0);

    return cycles;

  }

}

class JMP extends Instruction {

  JMP() : super('1001010kkkkk110k', opcodeSize: 2, cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x01F1, opcode); // 0000000111110001
    int dest = k << 16 | mcu.program[mcu.pc];

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${dest.toRadixString(16)}');
    }

    mcu.pc = dest;

    return cycles;

  }

}

class LD_X1 extends Instruction {

  LD_X1() : super('1001000ddddd1100', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d', 'X');
    }

    mcu.registers[d] = mcu.memory[mcu.rx];

    return cycles;

  }

}

class LD_X2 extends Instruction {

  LD_X2() : super('1001000ddddd1101', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.registers[d] = mcu.memory[mcu.rx];
    mcu.rx += 1;

    return cycles;

  }

}

class LD_X3 extends Instruction {

  LD_X3() : super('1001000ddddd1110', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.rx -= 1;
    mcu.registers[d] = mcu.memory[mcu.rx];

    return cycles;

  }

}

class LD_Y2 extends Instruction {

  LD_Y2() : super('1001000ddddd1001', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.registers[d] = mcu.memory[mcu.ry];
    mcu.ry += 1;

    return cycles;

  }

}

class LD_Y3 extends Instruction {

  LD_Y3() : super('1001000ddddd1010', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.ry -= 1;
    mcu.registers[d] = mcu.memory[mcu.ry];

    return cycles;

  }

}

class LD_Y4 extends Instruction {

  LD_Y4() : super('10q0qq0ddddd1qqq', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int q = variableValue(0x2C07, opcode); // 0010110000000111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d", q);
    }

    mcu.registers[d] = mcu.memory[mcu.ry + q];

    return cycles;

  }

}

class LD_Z2 extends Instruction {

  LD_Z2() : super('1001000ddddd0001', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.registers[d] = mcu.memory[mcu.rz];
    mcu.rz += 1;

    return cycles;

  }

}

class LD_Z3 extends Instruction {

  LD_Z3() : super('1001000ddddd0010', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    mcu.rz -= 1;
    mcu.registers[d] = mcu.memory[mcu.rz];

    return cycles;

  }

}

class LD_Z4 extends Instruction {

  LD_Z4() : super('10q0qq0ddddd0qqq', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int q = variableValue(0x2C07, opcode); // 0010110000000111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, q, "R$d");
    }

    mcu.registers[d] = mcu.memory[mcu.rz + q];

    return cycles;

  }

}

class LDI extends Instruction {

  LDI() : super('1110KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, 'R$d');
    }

    mcu.registers[d] = K;

    return cycles;

  }

}

class LDS extends Instruction {

  LDS() : super('1001000ddddd0000', opcodeSize: 2, cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    mcu.registers[d] = mcu.memory[mcu.program[mcu.pc++]];

    return cycles;

  }

}

class LPM_1 extends Instruction {

  LPM_1() : super('1001010111001000', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'Z');
    }

    mcu.registers[0] = mcu.flash[mcu.rz];

    return cycles;

  }

}

class LPM_2 extends Instruction {

  LPM_2() : super('1001000ddddd0100', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d', 'Z');
    }

    mcu.registers[d] = mcu.flash[mcu.rz];

    return cycles;

  }

}

class LPM_3 extends Instruction {

  LPM_3() : super('1001000ddddd0101', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d', mcu.rz);
    }

    mcu.registers[d] = mcu.flash[mcu.rz++];

    return cycles;

  }

}

class LSR extends Instruction {

  LSR() : super('1001010ddddd0110');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    var rd = mcu.registers[d];

    mcu.c = getBit(rd, 0);
    rd = rd >> 1;

    mcu.n = 0;
    mcu.v = mcu.n ^ mcu.c;
    mcu.s = mcu.n ^ mcu.v;
    mcu.z = boolToInt(rd == 0);

    mcu.registers[d] = rd;

    return cycles;

  }

}

class MOV extends Instruction {

  MOV() : super('001011rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    mcu.registers[d] = mcu.registers[r];

    return cycles;

  }

}

class MOVW extends Instruction {

  MOVW() : super('00000001ddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x00F0, opcode); // 0000000011110000
    int r = variableValue(0x000F, opcode); // 0000000000001111

    d *= 2;
    r *= 2;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    mcu.registers[d] = mcu.registers[r];
    mcu.registers[d + 1] = mcu.registers[r + 1];

    return cycles;

  }

}

class MUL extends Instruction {

  MUL() : super('100111rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    r += 16;
    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rr * rd;

    mcu.registers.writeWord(0, result);

    mcu.c = getBit(result, 15);
    mcu.z = boolToInt(result == 0);

    return cycles;

  }

}

class MULS extends Instruction {

  MULS() : super('00000010ddddrrrr', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x00F0, opcode); // 0000000011110000
    int r = variableValue(0x000F, opcode); // 0000000000001111

    r += 16;
    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }
    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rr * rd;

    mcu.registers.writeWord(0, result);

    mcu.c = getBit(result, 15);
    mcu.z = isZero(result);

    return cycles;

  }

}

class MULSU extends Instruction {

  MULSU() : super('000000110ddd0rrr', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x0070, opcode); // 0000000001110000
    int r = variableValue(0x0007, opcode); // 0000000000000111

    r += 16;
    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rr * rd;

    mcu.registers.writeWord(0, result);

    mcu.z = boolToInt(result == 0);
    mcu.c = getBit(result, 15);

    return cycles;

  }

}

class NEG extends Instruction {

  NEG() : super('1001010ddddd0001');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    var rd = mcu.registers[d];
    var result = -rd;

    mcu.h = getBit(result | rd, 3);
    mcu.v = boolToInt(result == 0x80);
    mcu.n = getBit(result, 7);
    mcu.z = boolToInt(result == 0);
    mcu.c = boolToInt(result != 0);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class NOP extends Instruction {

  NOP() : super('0000000000000000');

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    return cycles;

  }

}

class OR extends Instruction {

  OR() : super('001010rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rd | rr;

    mcu.n = getBit(result, 7);
    mcu.v = 0;
    mcu.s = mcu.n;
    mcu.z = isZero(result);

    mcu.registers[d] = result;

    return cycles;

  }

}

class ORI extends Instruction {

  ORI() : super('0110KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    d = d + 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, "R$d");
    }

    var result = mcu.registers[d] | K;

    mcu.n = getBit(result, 7);
    mcu.v = 0;
    mcu.s = mcu.n;
    mcu.z = isZero(result);

    mcu.registers[d] = result;

    return cycles;

  }

}

class OUT extends Instruction {

  OUT() : super('10111AArrrrrAAAA');

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x060F, opcode); // 0000011000001111
    int r = variableValue(0x01F0, opcode); // 0000000111110000

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}', 'R$r');
    }

    mcu.memory[A] = mcu.registers[r];

    return cycles;

  }

}

class POP extends Instruction {

  POP() : super('1001000ddddd1111', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    mcu.sp++;
    mcu.registers[d] = mcu.memory[mcu.sp];

    return cycles;

  }

}

class PUSH extends Instruction {

  PUSH() : super('1001001ddddd1111', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    mcu.memory[mcu.sp] = mcu.registers[d];
    mcu.sp--;

    return cycles;

  }

}

class RCALL extends Instruction {

  RCALL() : super('1101kkkkkkkkkkkk', cycles: 3);

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x0FFF, opcode); // 0000111111111111
    int k1 = (getBit(k, 11) == 1) ? (-((~k + 1) & 0x7FF)) : k;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, k1);
    }

    pushPC(mcu);
    mcu.pc += k1;

    return cycles;

  }

}

class RET extends Instruction {

  RET() : super('1001010100001000', cycles: 4);

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    mcu.pc = mcu.memory[mcu.sp + 1] | (mcu.memory[mcu.sp + 2] << 8);
    mcu.sp += 2;

    return cycles;

  }

}

class RETI extends Instruction {

  RETI() : super('1001010100011000', cycles: 4);

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    mcu.pc = mcu.memory[mcu.sp + 1] | (mcu.memory[mcu.sp + 2] << 8);
    mcu.sp += 2;
    mcu.i = 1;

    return cycles;

  }

}

class RJMP extends Instruction {

  RJMP() : super('1100kkkkkkkkkkkk', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int k = variableValue(0x0FFF, opcode); // 0000111111111111
    int k1 = (getBit(k, 11) == 1) ? (-((~k + 1) & 0x7FF)) : k;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, k1);
    }

    mcu.pc = (mcu.pc + k1);

    return cycles;

  }

}

class ROR extends Instruction {

  ROR() : super('1001010ddddd0111');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$d");
    }

    var rd = mcu.registers[d];
    int c = getBit(rd, 0);

    rd = setBit(rd >> 1, 7, mcu.c);

    mcu.n = getBit(rd, 7);
    mcu.v = mcu.n ^ mcu.c;
    mcu.s = mcu.n ^ mcu.v;
    mcu.z = boolToInt(rd == 0);
    mcu.c = c;

    return cycles;

  }

}

class SBC extends Instruction {

  SBC() : super('000010rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rr = mcu.registers[r];
    var rd = mcu.registers[d];

    var result = rd - rr - mcu.c;
    var carry = (~rd & rr) | (rr & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~rr & ~result) | (~rd & rr & result)), 7);
    mcu.n = getBit(result, 7);

    if (result != 0) {
      mcu.z = 0;
    }

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class SBCI extends Instruction {

  SBCI() : super('0100KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, 'R$d');
    }

    var rd = mcu.registers[d];

    var result = rd - K - mcu.c;
    var carry = (~rd & K) | (K & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~K & ~result) | (~rd & K & result)), 7);
    mcu.n = getBit(result, 7);

    if (result != 0) {
      mcu.z = 0;
    }

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class SBI extends Instruction {

  SBI() : super('10011010AAAAAbbb', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x00F8, opcode); // 0000000011111000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}: ${mcu.memory[A]}', b
          );
    }

    mcu.memory[A] = setBit(mcu.memory[A], b, 1);

    return cycles;

  }

}

class SBIC extends Instruction {

  SBIC() : super('10011001AAAAAbbb');

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x00F8, opcode); // 0000000011111000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}: ${mcu.memory[A]}', b
          );
    }

    int value = mcu.memory[A];

    if (getBit(value, b) == 0) {

      int opcodeSize = mcu.getCurrentInstruction().opcodeSize;

      mcu.pc += opcodeSize;
      return cycles + opcodeSize;

    }

    return cycles;

  }

}

class SBIS extends Instruction {

  SBIS() : super('10011011AAAAAbbb');

  int execute(MCUnit mcu, int opcode) {

    int A = variableValue(0x00F8, opcode); // 0000000011111000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    A += 0x20;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, '0x${A.toRadixString(16)}: ${mcu.memory[A]}', b
          );
    }

    int value = mcu.memory[A];

    if (getBit(value, b) != 0) {

      int opcodeSize = mcu.getCurrentInstruction().opcodeSize;

      mcu.pc += opcodeSize;
      return cycles + opcodeSize;

    }

    return cycles;

  }

}

class SBIW extends Instruction {

  SBIW() : super('10010111KKddKKKK', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x00CF, opcode); // 0000 0000 1100 1111
    int d = variableValue(0x0030, opcode); // 0000 0000 0011 0000

    d = d * 2 + 24;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, "R$d");
    }

    var rdw = mcu.registers.readWord(d);
    var result = rdw - K;

    mcu.v = getBit((rdw & ~result), 15);
    mcu.n = getBit(result, 15);
    mcu.z = isZero(result);
    mcu.c = getBit((result & ~rdw), 15);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers.writeWord(d, result);

    return cycles;

  }

}

class SBRC extends Instruction {

  SBRC() : super('1111110rrrrr0bbb');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$r", b);
    }

    var rr = mcu.registers[r];

    if (getBit(rr, b) == 0) {

      int opcodeSize = mcu.getCurrentInstruction().opcodeSize;

      mcu.pc += opcodeSize;
      return cycles + opcodeSize;

    }

    return cycles;

  }

}

class SBRS extends Instruction {

  SBRS() : super('1111111rrrrr0bbb');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000
    int b = variableValue(0x0007, opcode); // 0000000000000111

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, "R$r", b);
    }

    var rr = mcu.registers[r];

    if (getBit(rr, b) != 0) {

      int opcodeSize = mcu.getCurrentInstruction().opcodeSize;

      mcu.pc += opcodeSize;
      return cycles + opcodeSize;

    }

    return cycles;

  }

}

class SLEEP extends Instruction {

  SLEEP() : super('1001010110001000');

  int execute(MCUnit mcu, int opcode) {

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this);
    }

    return cycles;

  }

}

class SPM2_1 extends Instruction {

  SPM2_1() : super('1001010111101000');

  int execute(MCUnit mcu, int opcode) {


    logNotImplemented(this);

    return cycles;

  }

}

class SPM2_2 extends Instruction {

  SPM2_2() : super('1001010111111000');

  int execute(MCUnit mcu, int opcode) {


    logNotImplemented(this);

    return cycles;

  }

}

class ST_X1 extends Instruction {

  ST_X1() : super('1001001rrrrr1100', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'X');
    }

    mcu.memory[mcu.rx] = mcu.registers[r];

    return cycles;

  }

}

class ST_X2 extends Instruction {

  ST_X2() : super('1001001rrrrr1101', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'X+');
    }

    mcu.memory[mcu.rx] = mcu.registers[r];
    mcu.rx++;

    return cycles;

  }

}

class ST_X3 extends Instruction {

  ST_X3() : super('1001001rrrrr1110', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', '-X');
    }

    mcu.rx -= 1;
    mcu.memory[mcu.rx] = mcu.registers[r];

    return cycles;

  }

}

class ST_Y2 extends Instruction {

  ST_Y2() : super('1001001rrrrr1001', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'Y+');
    }

    mcu.memory[mcu.ry] = mcu.registers[r];
    mcu.ry += 1;

    return cycles;

  }

}

class ST_Y3 extends Instruction {

  ST_Y3() : super('1001001rrrrr1010', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', '-Y');
    }

    mcu.ry -= 1;
    mcu.memory[mcu.ry] = mcu.registers[r];

    return cycles;

  }

}

class ST_Y4 extends Instruction {

  ST_Y4() : super('10q0qq1rrrrr1qqq', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int q = variableValue(0x2C07, opcode); // 0010110000000111
    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', "Y + $q");
    }

    mcu.memory[mcu.ry + q] = mcu.registers[r];

    return cycles;

  }

}

class ST_Z2 extends Instruction {

  ST_Z2() : super('1001001rrrrr0001', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', "Z+");
    }

    mcu.memory[mcu.rz] = mcu.registers[r];
    mcu.rz += 1;

    return cycles;

  }

}

class ST_Z3 extends Instruction {

  ST_Z3() : super('1001001rrrrr0010', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', "-Z");
    }

    mcu.rz -= 1;
    mcu.memory[mcu.rz] = mcu.registers[r];

    return cycles;

  }

}

class ST_Z4 extends Instruction {

  ST_Z4() : super('10q0qq1rrrrr0qqq', cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int q = variableValue(0x2C07, opcode); // 0010110000000111
    int r = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', "Z + $q");
    }

    mcu.memory[mcu.rz + q] = mcu.registers[r];

    return cycles;

  }

}

class STS extends Instruction {

  STS() : super('1001001ddddd0000', opcodeSize: 2, cycles: 2);

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    mcu.memory[mcu.program[mcu.pc++]] = mcu.registers[d];

    return cycles;

  }

}

class SUB extends Instruction {

  SUB() : super('000110rdddddrrrr');

  int execute(MCUnit mcu, int opcode) {

    int r = variableValue(0x020F, opcode); // 0000001000001111
    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$r', 'R$d');
    }

    var rd = mcu.registers[d];
    var rr = mcu.registers[r];

    var result = rd - rr;
    var carry = (~rd & rr) | (rr & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~rr & ~result) | (~rd & rr & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class SUBI extends Instruction {

  SUBI() : super('0101KKKKddddKKKK');

  int execute(MCUnit mcu, int opcode) {

    int K = variableValue(0x0F0F, opcode); // 0000111100001111
    int d = variableValue(0x00F0, opcode); // 0000000011110000

    d += 16;

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, K, 'R$d');
    }

    var rd = mcu.registers[d];

    var result = rd - K;
    var carry = (~rd & K) | (K & result) | (result & ~rd);

    mcu.h = getBit(carry, 3);
    mcu.c = getBit(carry, 7);

    mcu.v = getBit(((rd & ~K & ~result) | (~rd & K & result)), 7);
    mcu.n = getBit(result, 7);
    mcu.z = isZero(result);

    mcu.s = mcu.n ^ mcu.v;

    mcu.registers[d] = result;

    return cycles;

  }

}

class SWAP extends Instruction {

  SWAP() : super('1001010ddddd0010');

  int execute(MCUnit mcu, int opcode) {

    int d = variableValue(0x01F0, opcode); // 0000000111110000

    if (log.isLoggable(Level.FINER)) {
      logInstruction(mcu, this, 'R$d');
    }

    mcu.registers[d] = (mcu.registers[d] << 4) | (mcu.registers[d] >> 4) &
        0xFFFF;

    return cycles;

  }

}

class WDR extends Instruction {

  WDR() : super('1001010110101000');

  int execute(MCUnit mcu, int opcode) {

    logNotImplemented(this);

    return cycles;

  }

}
