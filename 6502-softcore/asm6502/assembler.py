#!/usr/bin/env python3
"""
Mini Assembler para 6502
Gera arquivo .mif de 16KB com instruções começando no endereço 0x1000
"""

import re
import sys
from typing import Dict, List, Tuple, Optional

# Tamanho da memória em bytes (16KB)
MEMORY_SIZE = 16 * 1024  # 16384 bytes

# Endereço inicial das instruções
START_ADDRESS = 0x1000

# Modos de endereçamento
class AddressMode:
    IMPLIED = 'IMP'       # Implícito (sem operando)
    ACCUMULATOR = 'ACC'   # Acumulador
    IMMEDIATE = 'IMM'     # Imediato (#$XX)
    ZERO_PAGE = 'ZP'      # Página Zero ($XX)
    ZERO_PAGE_X = 'ZPX'   # Página Zero,X ($XX,X)
    ZERO_PAGE_Y = 'ZPY'   # Página Zero,Y ($XX,Y)
    ABSOLUTE = 'ABS'      # Absoluto ($XXXX)
    ABSOLUTE_X = 'ABX'    # Absoluto,X ($XXXX,X)
    ABSOLUTE_Y = 'ABY'    # Absoluto,Y ($XXXX,Y)
    INDIRECT = 'IND'      # Indireto ($XXXX)
    INDIRECT_X = 'INX'    # Indireto,X (($XX,X))
    INDIRECT_Y = 'INY'    # Indireto,Y (($XX),Y)
    RELATIVE = 'REL'      # Relativo (para branches)

# Tabela de opcodes do 6502
# Formato: {instrução: {modo: (opcode, tamanho)}}
OPCODES: Dict[str, Dict[str, Tuple[int, int]]] = {
    # ADC - Add with Carry
    'ADC': {
        AddressMode.IMMEDIATE: (0x69, 2),
        AddressMode.ZERO_PAGE: (0x65, 2),
        AddressMode.ZERO_PAGE_X: (0x75, 2),
        AddressMode.ABSOLUTE: (0x6D, 3),
        AddressMode.ABSOLUTE_X: (0x7D, 3),
        AddressMode.ABSOLUTE_Y: (0x79, 3),
        AddressMode.INDIRECT_X: (0x61, 2),
        AddressMode.INDIRECT_Y: (0x71, 2),
    },
    # AND - Logical AND
    'AND': {
        AddressMode.IMMEDIATE: (0x29, 2),
        AddressMode.ZERO_PAGE: (0x25, 2),
        AddressMode.ZERO_PAGE_X: (0x35, 2),
        AddressMode.ABSOLUTE: (0x2D, 3),
        AddressMode.ABSOLUTE_X: (0x3D, 3),
        AddressMode.ABSOLUTE_Y: (0x39, 3),
        AddressMode.INDIRECT_X: (0x21, 2),
        AddressMode.INDIRECT_Y: (0x31, 2),
    },
    # ASL - Arithmetic Shift Left
    'ASL': {
        AddressMode.ACCUMULATOR: (0x0A, 1),
        AddressMode.ZERO_PAGE: (0x06, 2),
        AddressMode.ZERO_PAGE_X: (0x16, 2),
        AddressMode.ABSOLUTE: (0x0E, 3),
        AddressMode.ABSOLUTE_X: (0x1E, 3),
    },
    # BCC - Branch if Carry Clear
    'BCC': {AddressMode.RELATIVE: (0x90, 2)},
    # BCS - Branch if Carry Set
    'BCS': {AddressMode.RELATIVE: (0xB0, 2)},
    # BEQ - Branch if Equal
    'BEQ': {AddressMode.RELATIVE: (0xF0, 2)},
    # BIT - Bit Test
    'BIT': {
        AddressMode.ZERO_PAGE: (0x24, 2),
        AddressMode.ABSOLUTE: (0x2C, 3),
    },
    # BMI - Branch if Minus
    'BMI': {AddressMode.RELATIVE: (0x30, 2)},
    # BNE - Branch if Not Equal
    'BNE': {AddressMode.RELATIVE: (0xD0, 2)},
    # BPL - Branch if Positive
    'BPL': {AddressMode.RELATIVE: (0x10, 2)},
    # BRK - Force Interrupt
    'BRK': {AddressMode.IMPLIED: (0x00, 1)},
    # BVC - Branch if Overflow Clear
    'BVC': {AddressMode.RELATIVE: (0x50, 2)},
    # BVS - Branch if Overflow Set
    'BVS': {AddressMode.RELATIVE: (0x70, 2)},
    # CLC - Clear Carry Flag
    'CLC': {AddressMode.IMPLIED: (0x18, 1)},
    # CLD - Clear Decimal Mode
    'CLD': {AddressMode.IMPLIED: (0xD8, 1)},
    # CLI - Clear Interrupt Disable
    'CLI': {AddressMode.IMPLIED: (0x58, 1)},
    # CLV - Clear Overflow Flag
    'CLV': {AddressMode.IMPLIED: (0xB8, 1)},
    # CMP - Compare
    'CMP': {
        AddressMode.IMMEDIATE: (0xC9, 2),
        AddressMode.ZERO_PAGE: (0xC5, 2),
        AddressMode.ZERO_PAGE_X: (0xD5, 2),
        AddressMode.ABSOLUTE: (0xCD, 3),
        AddressMode.ABSOLUTE_X: (0xDD, 3),
        AddressMode.ABSOLUTE_Y: (0xD9, 3),
        AddressMode.INDIRECT_X: (0xC1, 2),
        AddressMode.INDIRECT_Y: (0xD1, 2),
    },
    # CPX - Compare X Register
    'CPX': {
        AddressMode.IMMEDIATE: (0xE0, 2),
        AddressMode.ZERO_PAGE: (0xE4, 2),
        AddressMode.ABSOLUTE: (0xEC, 3),
    },
    # CPY - Compare Y Register
    'CPY': {
        AddressMode.IMMEDIATE: (0xC0, 2),
        AddressMode.ZERO_PAGE: (0xC4, 2),
        AddressMode.ABSOLUTE: (0xCC, 3),
    },
    # DEC - Decrement Memory
    'DEC': {
        AddressMode.ZERO_PAGE: (0xC6, 2),
        AddressMode.ZERO_PAGE_X: (0xD6, 2),
        AddressMode.ABSOLUTE: (0xCE, 3),
        AddressMode.ABSOLUTE_X: (0xDE, 3),
    },
    # DEX - Decrement X Register
    'DEX': {AddressMode.IMPLIED: (0xCA, 1)},
    # DEY - Decrement Y Register
    'DEY': {AddressMode.IMPLIED: (0x88, 1)},
    # EOR - Exclusive OR
    'EOR': {
        AddressMode.IMMEDIATE: (0x49, 2),
        AddressMode.ZERO_PAGE: (0x45, 2),
        AddressMode.ZERO_PAGE_X: (0x55, 2),
        AddressMode.ABSOLUTE: (0x4D, 3),
        AddressMode.ABSOLUTE_X: (0x5D, 3),
        AddressMode.ABSOLUTE_Y: (0x59, 3),
        AddressMode.INDIRECT_X: (0x41, 2),
        AddressMode.INDIRECT_Y: (0x51, 2),
    },
    # INC - Increment Memory
    'INC': {
        AddressMode.ZERO_PAGE: (0xE6, 2),
        AddressMode.ZERO_PAGE_X: (0xF6, 2),
        AddressMode.ABSOLUTE: (0xEE, 3),
        AddressMode.ABSOLUTE_X: (0xFE, 3),
    },
    # INX - Increment X Register
    'INX': {AddressMode.IMPLIED: (0xE8, 1)},
    # INY - Increment Y Register
    'INY': {AddressMode.IMPLIED: (0xC8, 1)},
    # JMP - Jump
    'JMP': {
        AddressMode.ABSOLUTE: (0x4C, 3),
        AddressMode.INDIRECT: (0x6C, 3),
    },
    # JSR - Jump to Subroutine
    'JSR': {AddressMode.ABSOLUTE: (0x20, 3)},
    # LDA - Load Accumulator
    'LDA': {
        AddressMode.IMMEDIATE: (0xA9, 2),
        AddressMode.ZERO_PAGE: (0xA5, 2),
        AddressMode.ZERO_PAGE_X: (0xB5, 2),
        AddressMode.ABSOLUTE: (0xAD, 3),
        AddressMode.ABSOLUTE_X: (0xBD, 3),
        AddressMode.ABSOLUTE_Y: (0xB9, 3),
        AddressMode.INDIRECT_X: (0xA1, 2),
        AddressMode.INDIRECT_Y: (0xB1, 2),
    },
    # LDX - Load X Register
    'LDX': {
        AddressMode.IMMEDIATE: (0xA2, 2),
        AddressMode.ZERO_PAGE: (0xA6, 2),
        AddressMode.ZERO_PAGE_Y: (0xB6, 2),
        AddressMode.ABSOLUTE: (0xAE, 3),
        AddressMode.ABSOLUTE_Y: (0xBE, 3),
    },
    # LDY - Load Y Register
    'LDY': {
        AddressMode.IMMEDIATE: (0xA0, 2),
        AddressMode.ZERO_PAGE: (0xA4, 2),
        AddressMode.ZERO_PAGE_X: (0xB4, 2),
        AddressMode.ABSOLUTE: (0xAC, 3),
        AddressMode.ABSOLUTE_X: (0xBC, 3),
    },
    # LSR - Logical Shift Right
    'LSR': {
        AddressMode.ACCUMULATOR: (0x4A, 1),
        AddressMode.ZERO_PAGE: (0x46, 2),
        AddressMode.ZERO_PAGE_X: (0x56, 2),
        AddressMode.ABSOLUTE: (0x4E, 3),
        AddressMode.ABSOLUTE_X: (0x5E, 3),
    },
    # NOP - No Operation
    'NOP': {AddressMode.IMPLIED: (0xEA, 1)},
    # ORA - Logical Inclusive OR
    'ORA': {
        AddressMode.IMMEDIATE: (0x09, 2),
        AddressMode.ZERO_PAGE: (0x05, 2),
        AddressMode.ZERO_PAGE_X: (0x15, 2),
        AddressMode.ABSOLUTE: (0x0D, 3),
        AddressMode.ABSOLUTE_X: (0x1D, 3),
        AddressMode.ABSOLUTE_Y: (0x19, 3),
        AddressMode.INDIRECT_X: (0x01, 2),
        AddressMode.INDIRECT_Y: (0x11, 2),
    },
    # PHA - Push Accumulator
    'PHA': {AddressMode.IMPLIED: (0x48, 1)},
    # PHP - Push Processor Status
    'PHP': {AddressMode.IMPLIED: (0x08, 1)},
    # PLA - Pull Accumulator
    'PLA': {AddressMode.IMPLIED: (0x68, 1)},
    # PLP - Pull Processor Status
    'PLP': {AddressMode.IMPLIED: (0x28, 1)},
    # ROL - Rotate Left
    'ROL': {
        AddressMode.ACCUMULATOR: (0x2A, 1),
        AddressMode.ZERO_PAGE: (0x26, 2),
        AddressMode.ZERO_PAGE_X: (0x36, 2),
        AddressMode.ABSOLUTE: (0x2E, 3),
        AddressMode.ABSOLUTE_X: (0x3E, 3),
    },
    # ROR - Rotate Right
    'ROR': {
        AddressMode.ACCUMULATOR: (0x6A, 1),
        AddressMode.ZERO_PAGE: (0x66, 2),
        AddressMode.ZERO_PAGE_X: (0x76, 2),
        AddressMode.ABSOLUTE: (0x6E, 3),
        AddressMode.ABSOLUTE_X: (0x7E, 3),
    },
    # RTI - Return from Interrupt
    'RTI': {AddressMode.IMPLIED: (0x40, 1)},
    # RTS - Return from Subroutine
    'RTS': {AddressMode.IMPLIED: (0x60, 1)},
    # SBC - Subtract with Carry
    'SBC': {
        AddressMode.IMMEDIATE: (0xE9, 2),
        AddressMode.ZERO_PAGE: (0xE5, 2),
        AddressMode.ZERO_PAGE_X: (0xF5, 2),
        AddressMode.ABSOLUTE: (0xED, 3),
        AddressMode.ABSOLUTE_X: (0xFD, 3),
        AddressMode.ABSOLUTE_Y: (0xF9, 3),
        AddressMode.INDIRECT_X: (0xE1, 2),
        AddressMode.INDIRECT_Y: (0xF1, 2),
    },
    # SEC - Set Carry Flag
    'SEC': {AddressMode.IMPLIED: (0x38, 1)},
    # SED - Set Decimal Flag
    'SED': {AddressMode.IMPLIED: (0xF8, 1)},
    # SEI - Set Interrupt Disable
    'SEI': {AddressMode.IMPLIED: (0x78, 1)},
    # STA - Store Accumulator
    'STA': {
        AddressMode.ZERO_PAGE: (0x85, 2),
        AddressMode.ZERO_PAGE_X: (0x95, 2),
        AddressMode.ABSOLUTE: (0x8D, 3),
        AddressMode.ABSOLUTE_X: (0x9D, 3),
        AddressMode.ABSOLUTE_Y: (0x99, 3),
        AddressMode.INDIRECT_X: (0x81, 2),
        AddressMode.INDIRECT_Y: (0x91, 2),
    },
    # STX - Store X Register
    'STX': {
        AddressMode.ZERO_PAGE: (0x86, 2),
        AddressMode.ZERO_PAGE_Y: (0x96, 2),
        AddressMode.ABSOLUTE: (0x8E, 3),
    },
    # STY - Store Y Register
    'STY': {
        AddressMode.ZERO_PAGE: (0x84, 2),
        AddressMode.ZERO_PAGE_X: (0x94, 2),
        AddressMode.ABSOLUTE: (0x8C, 3),
    },
    # TAX - Transfer Accumulator to X
    'TAX': {AddressMode.IMPLIED: (0xAA, 1)},
    # TAY - Transfer Accumulator to Y
    'TAY': {AddressMode.IMPLIED: (0xA8, 1)},
    # TSX - Transfer Stack Pointer to X
    'TSX': {AddressMode.IMPLIED: (0xBA, 1)},
    # TXA - Transfer X to Accumulator
    'TXA': {AddressMode.IMPLIED: (0x8A, 1)},
    # TXS - Transfer X to Stack Pointer
    'TXS': {AddressMode.IMPLIED: (0x9A, 1)},
    # TYA - Transfer Y to Accumulator
    'TYA': {AddressMode.IMPLIED: (0x98, 1)},
}

# Instruções de branch (usam endereçamento relativo)
BRANCH_INSTRUCTIONS = {'BCC', 'BCS', 'BEQ', 'BMI', 'BNE', 'BPL', 'BVC', 'BVS'}


class Assembler6502:
    def __init__(self):
        self.memory = bytearray(MEMORY_SIZE)
        self.labels: Dict[str, int] = {}
        self.current_address = START_ADDRESS
        self.pending_labels: List[Tuple[int, str, int]] = []  # (address, label, instruction_size)

    def parse_value(self, value_str: str) -> int:
        """Parse um valor numérico (hex ou decimal)"""
        value_str = value_str.strip()
        if value_str.startswith('$'):
            return int(value_str[1:], 16)
        elif value_str.startswith('0x') or value_str.startswith('0X'):
            return int(value_str[2:], 16)
        elif value_str.startswith('%'):
            return int(value_str[1:], 2)
        else:
            return int(value_str)

    def detect_address_mode(self, operand: str, instruction: str) -> Tuple[str, Optional[int], Optional[str]]:
        """
        Detecta o modo de endereçamento baseado no operando
        Retorna: (modo, valor, label)
        """
        operand = operand.strip()

        # Sem operando - implícito ou acumulador
        if not operand:
            if instruction in OPCODES and AddressMode.ACCUMULATOR in OPCODES[instruction]:
                return AddressMode.ACCUMULATOR, None, None
            return AddressMode.IMPLIED, None, None

        # Acumulador explícito
        if operand.upper() == 'A':
            return AddressMode.ACCUMULATOR, None, None

        # Imediato: #$XX ou #XX
        match = re.match(r'^#(.+)$', operand)
        if match:
            value = self.parse_value(match.group(1))
            return AddressMode.IMMEDIATE, value, None

        # Indireto,X: ($XX,X)
        match = re.match(r'^\((.+),\s*X\)$', operand, re.IGNORECASE)
        if match:
            value = self.parse_value(match.group(1))
            return AddressMode.INDIRECT_X, value, None

        # Indireto,Y: ($XX),Y
        match = re.match(r'^\((.+)\),\s*Y$', operand, re.IGNORECASE)
        if match:
            value = self.parse_value(match.group(1))
            return AddressMode.INDIRECT_Y, value, None

        # Indireto: ($XXXX) - apenas para JMP
        match = re.match(r'^\((.+)\)$', operand)
        if match:
            value = self.parse_value(match.group(1))
            return AddressMode.INDIRECT, value, None

        # Absoluto,X ou Página Zero,X: $XXXX,X ou $XX,X
        match = re.match(r'^(.+),\s*X$', operand, re.IGNORECASE)
        if match:
            val_str = match.group(1).strip()
            # Check if it's a label
            if not val_str.startswith('$') and not val_str.startswith('0x') and not val_str[0].isdigit():
                return AddressMode.ABSOLUTE_X, None, val_str
            value = self.parse_value(val_str)
            if value <= 0xFF:
                return AddressMode.ZERO_PAGE_X, value, None
            return AddressMode.ABSOLUTE_X, value, None

        # Absoluto,Y ou Página Zero,Y: $XXXX,Y ou $XX,Y
        match = re.match(r'^(.+),\s*Y$', operand, re.IGNORECASE)
        if match:
            val_str = match.group(1).strip()
            if not val_str.startswith('$') and not val_str.startswith('0x') and not val_str[0].isdigit():
                return AddressMode.ABSOLUTE_Y, None, val_str
            value = self.parse_value(val_str)
            if value <= 0xFF:
                return AddressMode.ZERO_PAGE_Y, value, None
            return AddressMode.ABSOLUTE_Y, value, None

        # Verificar se é um label
        if not operand.startswith('$') and not operand.startswith('0x') and not operand[0].isdigit():
            # É um label
            if instruction in BRANCH_INSTRUCTIONS:
                return AddressMode.RELATIVE, None, operand
            return AddressMode.ABSOLUTE, None, operand

        # Absoluto ou Página Zero: $XXXX ou $XX
        value = self.parse_value(operand)

        # Branch instructions sempre usam relativo
        if instruction in BRANCH_INSTRUCTIONS:
            return AddressMode.RELATIVE, value, None

        if value <= 0xFF:
            return AddressMode.ZERO_PAGE, value, None
        return AddressMode.ABSOLUTE, value, None

    def first_pass(self, lines: List[str]) -> None:
        """Primeira passagem: coleta labels e calcula endereços"""
        self.current_address = START_ADDRESS
        self.labels = {}

        for line_num, line in enumerate(lines, 1):
            # Remove comentários
            if ';' in line:
                line = line[:line.index(';')]
            line = line.strip()

            if not line:
                continue

            # Verifica se é um label
            if ':' in line:
                parts = line.split(':', 1)
                label = parts[0].strip()
                self.labels[label] = self.current_address
                line = parts[1].strip() if len(parts) > 1 else ''
                if not line:
                    continue

            # Parse da instrução
            parts = line.split(None, 1)
            instruction = parts[0].upper()
            operand = parts[1] if len(parts) > 1 else ''

            # Diretiva .ORG
            if instruction == '.ORG':
                self.current_address = self.parse_value(operand)
                continue

            # Diretiva .BYTE
            if instruction == '.BYTE':
                bytes_data = [self.parse_value(b.strip()) for b in operand.split(',')]
                self.current_address += len(bytes_data)
                continue

            # Diretiva .WORD
            if instruction == '.WORD':
                words_data = operand.split(',')
                self.current_address += len(words_data) * 2
                continue

            if instruction not in OPCODES:
                raise ValueError(f"Linha {line_num}: Instrução desconhecida '{instruction}'")

            # Detecta modo de endereçamento para calcular tamanho
            mode, _, _ = self.detect_address_mode(operand, instruction)

            if mode not in OPCODES[instruction]:
                raise ValueError(f"Linha {line_num}: Modo de endereçamento '{mode}' inválido para '{instruction}'")

            _, size = OPCODES[instruction][mode]
            self.current_address += size

    def write_byte(self, address: int, value: int) -> None:
        """Escreve um byte na memória se estiver dentro do range"""
        if 0 <= address < MEMORY_SIZE:
            self.memory[address] = value & 0xFF

    def second_pass(self, lines: List[str]) -> None:
        """Segunda passagem: gera código de máquina"""
        self.current_address = START_ADDRESS

        for line_num, line in enumerate(lines, 1):
            # Remove comentários
            if ';' in line:
                line = line[:line.index(';')]
            line = line.strip()

            if not line:
                continue

            # Remove label se presente
            if ':' in line:
                parts = line.split(':', 1)
                line = parts[1].strip() if len(parts) > 1 else ''
                if not line:
                    continue

            # Parse da instrução
            parts = line.split(None, 1)
            instruction = parts[0].upper()
            operand = parts[1] if len(parts) > 1 else ''

            # Diretiva .ORG
            if instruction == '.ORG':
                self.current_address = self.parse_value(operand)
                continue

            # Diretiva .BYTE
            if instruction == '.BYTE':
                bytes_data = [self.parse_value(b.strip()) for b in operand.split(',')]
                for byte in bytes_data:
                    self.write_byte(self.current_address, byte)
                    self.current_address += 1
                continue

            # Diretiva .WORD
            if instruction == '.WORD':
                words_data = operand.split(',')
                for word_str in words_data:
                    word_str = word_str.strip()
                    # Check if it's a label
                    if not word_str.startswith('$') and not word_str.startswith('0x') and not word_str[0].isdigit():
                        if word_str in self.labels:
                            word = self.labels[word_str]
                        else:
                            raise ValueError(f"Linha {line_num}: Label desconhecido '{word_str}'")
                    else:
                        word = self.parse_value(word_str)
                    self.write_byte(self.current_address, word & 0xFF)  # Low byte
                    self.write_byte(self.current_address + 1, (word >> 8) & 0xFF)  # High byte
                    self.current_address += 2
                continue

            # Detecta modo de endereçamento
            mode, value, label = self.detect_address_mode(operand, instruction)

            # Resolve label se necessário
            if label:
                if label not in self.labels:
                    raise ValueError(f"Linha {line_num}: Label desconhecido '{label}'")
                value = self.labels[label]

            # Obtém opcode e tamanho
            opcode, size = OPCODES[instruction][mode]

            # Escreve opcode
            self.write_byte(self.current_address, opcode)

            # Escreve operando
            if size >= 2:
                if mode == AddressMode.RELATIVE:
                    # Calcula offset relativo para branches
                    offset = value - (self.current_address + 2)
                    if offset < -128 or offset > 127:
                        raise ValueError(f"Linha {line_num}: Branch fora do alcance ({offset})")
                    self.write_byte(self.current_address + 1, offset & 0xFF)
                else:
                    self.write_byte(self.current_address + 1, value & 0xFF)

            if size == 3:
                self.write_byte(self.current_address + 2, (value >> 8) & 0xFF)

            self.current_address += size

    def assemble(self, source: str) -> None:
        """Assembla o código fonte"""
        lines = source.split('\n')
        self.first_pass(lines)
        self.second_pass(lines)

    def assemble_file(self, filename: str) -> None:
        """Assembla um arquivo"""
        with open(filename, 'r') as f:
            source = f.read()
        self.assemble(source)

    def generate_mif(self, output_filename: str) -> None:
        """Gera arquivo MIF de 16KB"""
        with open(output_filename, 'w') as f:
            f.write("-- Memory Initialization File (.mif)\n")
            f.write("-- Generated by Mini Assembler 6502\n")
            f.write("-- Instructions start at address 0x1000\n\n")
            f.write(f"DEPTH = {MEMORY_SIZE};\n")
            f.write("WIDTH = 8;\n")
            f.write("ADDRESS_RADIX = HEX;\n")
            f.write("DATA_RADIX = HEX;\n\n")
            f.write("CONTENT BEGIN\n")

            # Agrupa bytes consecutivos iguais para compactação
            i = 0
            while i < MEMORY_SIZE:
                value = self.memory[i]

                # Encontra sequência de bytes iguais
                j = i + 1
                while j < MEMORY_SIZE and self.memory[j] == value:
                    j += 1

                if j - i > 1:
                    # Range de valores iguais
                    f.write(f"    [{i:04X}..{j-1:04X}] : {value:02X};\n")
                else:
                    # Valor único
                    f.write(f"    {i:04X} : {value:02X};\n")

                i = j

            f.write("END;\n")

        print(f"Arquivo MIF gerado: {output_filename}")

    def print_memory(self, start: int = START_ADDRESS, length: int = 64) -> None:
        """Imprime uma seção da memória para debug"""
        print(f"\nMemória a partir de ${start:04X}:")
        for i in range(start, min(start + length, MEMORY_SIZE), 16):
            hex_values = ' '.join(f'{self.memory[j]:02X}' for j in range(i, min(i + 16, MEMORY_SIZE)))
            print(f"${i:04X}: {hex_values}")


def main():
    if len(sys.argv) < 2:
        print("Uso: python assembler.py <arquivo.asm> [arquivo_saida.mif]")
        print("\nExemplo:")
        print("  python assembler.py programa.asm")
        print("  python assembler.py programa.asm saida.mif")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.rsplit('.', 1)[0] + '.mif'

    try:
        assembler = Assembler6502()
        assembler.assemble_file(input_file)
        assembler.generate_mif(output_file)

        # Mostra os primeiros bytes para verificação
        assembler.print_memory(START_ADDRESS, 64)

        print(f"\nLabels encontrados:")
        for label, addr in assembler.labels.items():
            print(f"  {label}: ${addr:04X}")

    except FileNotFoundError:
        print(f"Erro: Arquivo '{input_file}' não encontrado.")
        sys.exit(1)
    except ValueError as e:
        print(f"Erro de montagem: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Erro: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

