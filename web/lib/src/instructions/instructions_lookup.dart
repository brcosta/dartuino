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

final List<Instruction> instructionsLookup = new List<Instruction>(65536);
final List<Instruction> allInstructions = new List<Instruction>();

var initialized = false;
/**
 * Initialize array with all Atmega instructions.
 */
initializeInstructions() {

  if (initialized) {
    return;
  }
  
  allInstructions.add(new ADC());
  allInstructions.add(new ADD());
  allInstructions.add(new ADIW());
  allInstructions.add(new AND());
  allInstructions.add(new ANDI());
  allInstructions.add(new ASR());
  allInstructions.add(new BCLR());
  allInstructions.add(new BLD());
  allInstructions.add(new BRBC());
  allInstructions.add(new BRBS());
  allInstructions.add(new BREAK());
  allInstructions.add(new BSET());
  allInstructions.add(new BST());
  allInstructions.add(new CALL());
  allInstructions.add(new CBI());
  allInstructions.add(new COM());
  allInstructions.add(new CP());
  allInstructions.add(new CPC());
  allInstructions.add(new CPI());
  allInstructions.add(new CPSE());
  allInstructions.add(new DEC());
  allInstructions.add(new DES());
  allInstructions.add(new EICALL());
  allInstructions.add(new EIJMP());
  allInstructions.add(new ELPM_1());
  allInstructions.add(new ELPM_2());
  allInstructions.add(new ELPM_3());
  allInstructions.add(new EOR());
  allInstructions.add(new FMUL());
  allInstructions.add(new FMULS());
  allInstructions.add(new FMULSU());
  allInstructions.add(new ICALL());
  allInstructions.add(new IJMP());
  allInstructions.add(new IN());
  allInstructions.add(new INC());
  allInstructions.add(new JMP());
  allInstructions.add(new LD_X1());
  allInstructions.add(new LD_X2());
  allInstructions.add(new LD_X3());
  allInstructions.add(new LD_Y2());
  allInstructions.add(new LD_Y3());
  allInstructions.add(new LD_Y4());
  allInstructions.add(new LD_Z2());
  allInstructions.add(new LD_Z3());
  allInstructions.add(new LD_Z4());
  allInstructions.add(new LDI());
  allInstructions.add(new LDS());
  allInstructions.add(new LPM_1());
  allInstructions.add(new LPM_2());
  allInstructions.add(new LPM_3());
  allInstructions.add(new LSR());
  allInstructions.add(new MOV());
  allInstructions.add(new MOVW());
  allInstructions.add(new MUL());
  allInstructions.add(new MULS());
  allInstructions.add(new MULSU());
  allInstructions.add(new NEG());
  allInstructions.add(new NOP());
  allInstructions.add(new OR());
  allInstructions.add(new ORI());
  allInstructions.add(new OUT());
  allInstructions.add(new POP());
  allInstructions.add(new PUSH());
  allInstructions.add(new RCALL());
  allInstructions.add(new RET());
  allInstructions.add(new RETI());
  allInstructions.add(new RJMP());
  allInstructions.add(new ROR());
  allInstructions.add(new SBC());
  allInstructions.add(new SBCI());
  allInstructions.add(new SBI());
  allInstructions.add(new SBIC());
  allInstructions.add(new SBIS());
  allInstructions.add(new SBIW());
  allInstructions.add(new SBRC());
  allInstructions.add(new SBRS());
  allInstructions.add(new SLEEP());
  allInstructions.add(new SPM2_1());
  allInstructions.add(new SPM2_2());
  allInstructions.add(new ST_X1());
  allInstructions.add(new ST_X2());
  allInstructions.add(new ST_X3());
  allInstructions.add(new ST_Y2());
  allInstructions.add(new ST_Y3());
  allInstructions.add(new ST_Y4());
  allInstructions.add(new ST_Z2());
  allInstructions.add(new ST_Z3());
  allInstructions.add(new ST_Z4());
  allInstructions.add(new STS());
  allInstructions.add(new SUB());
  allInstructions.add(new SUBI());
  allInstructions.add(new SWAP());
  allInstructions.add(new WDR());
  
  initializeInstructionsLookup();
  initialized = true;

}

/**
 * Generates a instruction lookup
 */
initializeInstructionsLookup() {

  for (var i = 0; i < instructionsLookup.length; i++) {
    instructionsLookup[i] = allInstructions.firstWhere((x) => (i & x.mask) == x.discriminator, orElse: () => allInstructions[12]);
  }

}
