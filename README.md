# 🧠 **MiniCPU-8 — Processador de 8 bits em FPGA (Cyclone IV)**

### Implementado em Verilog para a placa **EP4CE6E22C8N**

Este repositório contém a implementação completa de um processador simples de 8 bits projetado do zero em Verilog, incluindo:

✔ Arquitetura própria
✔ Registradores A, X, Y, PC, SP e PS
✔ Pipeline simples baseado em **FSM de 5 estágios**
✔ Instruções inspiradas no 6502 (ADC, SBC, JSR, RTS, LDA, BEQ, BNE…)
✔ Modos de endereçamento imediato, zeropage, absoluto e indireto
✔ Memória RAM 16 KB
✔ ALU completa com operações lógicas, aritméticas e shifts/rotates
✔ Suporte à utilização de stack para operações de push/pop e chamadas de função (JSR/RTS)
✔ Interface de monitoramento via display de 7 segmentos
✔ Totalmente sintetizável na **Cyclone IV EP4CE6E22C8N**

---

# 📐 **Arquitetura**

A CPU possui os seguintes registradores internos:

| Registrador | Largura | Função                                       |
| ----------- | ------- | -------------------------------------------- |
| **A**       | 8 bits  | Acumulador principal                         |
| **X**       | 8 bits  | Index register                               |
| **Y**       | 8 bits  | Index register                               |
| **PC**      | 16 bits | Program Counter                              |
| **SP**      | 8 bits  | Stack Pointer (suporte ampliado para stack)  |
| **PS**      | 8 bits  | Processor Status  |

### **Flags implementados:**

| Flag  | Bit | Descrição                     |
| ----- | --- | ----------------------------- |
| **Z** | 0   | Zero flag                     |
| **C** | 1   | Carry flag                    |
| **N** | 2   | Negative (bit 7 do resultado) |
| **V** | 3   | Overflow                      |

---

# ⚙️ **Pipeline / FSM**

A CPU é controlada por uma FSM de 5 estágios:

1. **FETCH**
   PC → RAM
   Lê opcode
2. **DECODE**
   Decodifica instrução + determina tamanho e modo de endereçamento
3. **READ**
   Lê operandos (1 ou 2 bytes) conforme o modo
4. **EXECUTE**
   Executa ALU, branch, JMP ou prepara escrita em memória
5. **WRITEBACK**
   Escreve resultado em registrador/memória e atualiza PC

Cada estágio possui sub-estágios para sincronização com a RAM:

* `SUB_SET_ADDR`
* `SUB_WAIT`
* `SUB_CAPTURE`

---

# 🧮 **ALU**

A ALU suporta:

* ADD / SUB (ADC, SBC)
* INC / DEC
* AND / OR / XOR
* ASL / LSR
* ROL / ROR
* PASS-THROUGH (movimento interno)

As operações atualizam os 4 flags básicos.

---

# 📦 **Modos de Endereçamento**

| Código | Nome        | Descrição                                    |
| ------ | ----------- | -------------------------------------------- |
| `00`   | Implied     | Operação sem operandos (INX, ROR A…)         |
| `01`   | Immediate   | Byte seguinte é o operando                   |
| `02`   | Zero Page   | Endereço 8 bits (endereça RAM 0x0000–0x00FF) |
| `03`   | Absolute    | Dois bytes de endereço                       |
| `04`   | Indirect    | Ponteiro armazenado no endereço fornecido    |

### **Branch utiliza endereçamento relativo**

O offset é um valor signed de 8 bits:

```
novo_PC = PC + offset + 2
```

---

# 📚 **Conjunto de Instruções Implementadas**

## **Carregamento e Armazenamento**

| Instrução       | Formato | Descrição               |
| --------------- | ------- | ----------------------- |
| `LDA #imm` (A9) | 2 bytes | Carrega imediato em A   |
| `LDA zp` (A5)   | 2 bytes | Carrega da RAM zeropage |
| `LDX #imm` (A2) |         | Carrega imediato em X   |
| `LDY #imm` (A0) |         | Carrega imediato em Y   |
| `STA zp` (85)   |         | Armazena A na zeropage  |
| `STX zp` (86)   |         | Armazena X              |
| `STY zp` (84)   |         | Armazena Y              |

---

## **Aritméticas & Lógicas (Sempre salva em A)**

| Mnemonic | Opcode | Operação   |
| -------- | ------ | ---------- |
| ADC      | 69     | A = A + op |
| SBC      | E9     | A = A – op |
| AND      | 29     | A = A & op |
| ORA      | 09     | A = A | op |
| XOR      | 49     | A = A ^ op |

---

## **Shifts e Rotates (somente A)**

| Mnemonic | Opcode | Operação     |
| -------- | ------ | ------------ |
| ASL A    | 0A     | Shift left   |
| LSR A    | 4A     | Shift right  |
| ROL A    | 2A     | Rotate left  |
| ROR A    | 6A     | Rotate right |

---

## **Incremento / Decremento**

| Mnemonic | Opcode | Afeta             |
| -------- | ------ | ----------------- |
| INX      | E8     | X = X + 1         |
| DEX      | CA     | X = X – 1         |
| INY      | C8     | Y = Y + 1         |
| DEY      | 88     | Y = Y – 1         |
| INC zp   | E6     | M[zp] = M[zp] + 1 |
| DEC zp   | C6     | M[zp] = M[zp] – 1 |

---

## **Controle de Fluxo**

| Mnemonic | Opcode | Ação                   |
| -------- | ------ | ---------------------- |
| JMP abs  | 4C     | PC ← endereço absoluto |
| JMP ind  | 6C     | PC ← endereço indireto |
| JSR abs  | 20     | Stack ← PC, Salto      |
| RTS      | 60     | Retorna do subprograma |
| BEQ rel  | F0     | if Z==1 branch         |
| BNE rel  | D0     | if Z==0 branch         |

---

# 🧱 **Memória**

A CPU utiliza uma RAM síncrona de:

* **16 KB**
* Endereçada por 16 bits
* Single-port
* Ciclos síncronos de leitura/escrita

---

# 🖥️ **Módulo de Monitoramento (cpu_monitor)**

Permite visualizar valores internos através de 4 botões:

| Botão    | Valor exibido     |
| -------- | ----------------- |
| `btn[0]` | Registrador **Y** |
| `btn[1]` | Registrador **A** |
| `btn[2]` | Registrador **X** |
| nenhum   | Program Counter   |

O display mostra **16 bits em hexadecimal**, usando o módulo `sled_monitor`.

---

# 🧩 **Organização do Sistema**

```
/src
 ├── control_unit.v
 ├── decoder.v
 ├── alu.v
 ├── cpu_register.v
 ├── ram16k.v
 ├── cpu_monitor.v
 ├── alu_defines.vh
```

---

# 💻 **Síntese na Cyclone IV**

A CPU foi projetada especificamente para:

> **EP4CE6E22C8N — Cyclone IV E (Altera/Intel)**

* Compatível com **Quartus Prime Lite**
* Frequência típica de operação: 25–50 MHz
* Uso de LUTs estimado: ~15–20%
* RAM interna armazenada em M9K blocks

---

# 🧪 **Exemplo de Programa**

```
      LDX #05     ; X = 5
loop: INX         ; X++
      STX $10     ; Guarda X na RAM
      LDA $10
      BEQ end     ; nunca acontece
      JMP loop
end:  JMP end
```

---

# 📝 **Estado Atual / Próximos Passos**

* [x] ALU completa
* [x] Registradores A, X, Y
* [x] JMP / BEQ / BNE funcionando
* [x] Stack funcionando (Push/Pop, JSR/RTS)
* [x] Monitor com display
* [ ] Interrupções
* [ ] Modo absoluto para mais instruções
* [ ] Montador simples

---

# 📜 **Licença**

MIT — livre para uso acadêmico, pessoal e aprendizagem.
---

# 🙌 **Autor**

**Lucas Oliveira**
Estudante de Engenharia de Computação — UEFS

---
