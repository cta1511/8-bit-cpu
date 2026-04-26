# 8-bit CPU

Đồ án mô phỏng một CPU 8-bit bằng Verilog. Thiết kế gồm Program Counter, Instruction Memory, Control Unit, Datapath, Register File, Data Memory và ALU 8-bit. Chương trình mẫu trong repo đọc 8 giá trị từ bộ nhớ dữ liệu, cộng dồn chúng bằng ALU, sau đó dừng và xuất trạng thái thanh ghi/bộ nhớ ra file để kiểm tra.

Repo GitHub: [https://github.com/cta1511/8-bit-CPU](https://github.com/cta1511/8-bit-CPU)

## Mục Tiêu Đồ Án

Mục tiêu chính của đồ án là xây dựng và mô phỏng một bộ xử lý 8-bit đơn giản ở mức RTL:

- Dùng bộ đếm chương trình 6-bit để duyệt tối đa 64 lệnh.
- Lưu lệnh dạng 32-bit trong Instruction Memory.
- Giải mã opcode bằng Control Unit.
- Thực thi phép toán qua Datapath và ALU.
- Hỗ trợ Register File gồm 32 thanh ghi, mỗi thanh ghi 8-bit.
- Hỗ trợ Data Memory gồm 256 ô nhớ, mỗi ô 8-bit.
- Hỗ trợ các nhóm lệnh nạp tức thời, load/store, ALU và halt.
- Xuất kết quả mô phỏng ra `reg_out.o`, `data_out.o` và waveform `main.vcd`.

## Kiến Trúc Tổng Quan

CPU được tổ chức theo luồng fetch -> decode -> execute -> memory/write-back.

```mermaid
flowchart LR
    CLK["clk/reset"] --> PC["pc6<br/>Program Counter 6-bit"]
    PC -->|q[5:0]| IR["ir8<br/>Instruction Memory 64 x 32"]
    IR -->|instr[31:0]| CTRL["control<br/>Control Unit"]
    IR -->|fields| DP["datapath"]
    CTRL -->|op, mread, mwrite, alusrc,<br/>rdt, mtr, rwrite, regprint| DP

    subgraph DATAPATH["Datapath"]
        RF["reg8<br/>32 x 8 Register File"]
        ALU["alu8<br/>8-bit ALU"]
        MEM["mem8<br/>Data Memory 256 x 8"]
        WB["Write-back Mux"]
        RF --> ALU
        ALU --> WB
        MEM --> WB
        WB --> RF
        RF --> MEM
    end
```

Luồng hoạt động trong `main8.v`:

1. `pc6` nhận `clk/reset` và tạo địa chỉ lệnh `q[5:0]`.
2. `ir8` dùng `q` để đọc một instruction 32-bit từ `test.prog`.
3. `control` lấy `opcode = instr[31:26]` và sinh các tín hiệu điều khiển.
4. `datapath` tách các field trong instruction, đọc Register File, chạy ALU hoặc Data Memory, rồi ghi kết quả về thanh ghi.
5. Khi gặp `hlt`, `regprint = 1`, hệ thống xuất trạng thái cuối ra `reg_out.o` và `data_out.o`.

## Cấu Trúc Thư Mục

```text
.
├── main8.v                         # Top-level CPU
├── main8_tb.v                      # Testbench mô phỏng toàn bộ CPU
├── datapath.v                      # Datapath: register, ALU, memory, write-back
├── control.v                       # Control Unit giải mã opcode
├── control_tb.v                    # Testbench Control Unit
├── scheme.txt                      # Bảng điều khiển, instruction set, chương trình mẫu
├── Report.pptx                     # File báo cáo quá trình
├── ProgramCounter/
│   ├── pc6.v                       # Program Counter 6-bit
│   ├── tff1.v                      # T flip-flop dùng để tạo bộ đếm
│   ├── pc6_tb.v                    # Testbench Program Counter
│   └── mota_pc.txt                 # Mô tả Program Counter
├── InstructionRegister/
│   ├── ir8.v                       # Instruction Memory 64 x 32
│   ├── ir8_tb.v                    # Testbench Instruction Memory
│   ├── test.prog                   # Chương trình mẫu gồm 64 lệnh 32-bit
│   └── mota_rom_ir8.txt            # Mô tả Instruction Memory
├── DataMemory/
│   ├── mem8.v                      # Data Memory 256 x 8
│   ├── mem8_tb.v                   # Testbench Data Memory
│   ├── test.data                   # Dữ liệu khởi tạo RAM
│   └── mota_ocung_mem8.txt         # Mô tả Data Memory
├── GPIOs/
│   ├── reg8.v                      # Register File 32 x 8
│   ├── reg8_tb.v                   # Testbench Register File
│   └── mota_ram_reg8.txt           # Mô tả Register File
└── ALU/
    ├── alu8.v                      # ALU chính
    ├── alu8_tb.v                   # Testbench ALU
    ├── mota.txt                    # Mô tả tổng quan ALU
    ├── 8 bit recursive dabling adder/
    │   └── rd8.v                   # Bộ cộng/trừ 8-bit
    ├── 8 bit wallace tree multiplication/
    │   └── wtm8.v                  # Bộ nhân Wallace Tree 8-bit
    ├── 8 bit non restoring division/
    │   └── nrd8.v                  # Bộ chia Non-Restoring 8-bit
    └── 8 bit barrel shifter/
        └── bs8.v                   # Barrel Shifter 8-bit
```

## Các Module Chính

### `main8.v`

`main8` là top-level module của CPU.

Port:

| Tên | Hướng | Độ rộng | Chức năng |
| --- | --- | --- | --- |
| `clk` | input | 1 bit | Clock mô phỏng CPU |
| `reset` | input | 1 bit | Reset Program Counter, active-high |

Các khối được nối trong `main8`:

- `pc6 ppp(clk, reset, q)`: tạo địa chỉ instruction.
- `ir8 iii(q, instr)`: đọc instruction từ ROM.
- `datapath daa(...)`: thực thi instruction.
- `control con(...)`: giải mã opcode và cấp tín hiệu điều khiển.

### `pc6.v`

`pc6` là bộ đếm chương trình 6-bit, đếm từ `0` đến `63`.

- Dùng 6 T flip-flop nối tầng.
- `reset = 1` đưa `q` về `0`.
- Mỗi chu kỳ clock làm PC tăng, từ đó trỏ đến instruction kế tiếp trong ROM.
- Độ rộng 6-bit tương ứng 64 địa chỉ lệnh.

### `ir8.v`

`ir8` là Instruction Memory.

- Kích thước: 64 dòng x 32-bit.
- Địa chỉ đọc: `out_address[5:0]`.
- Dữ liệu ra: `out_data[31:0]`.
- Nạp instruction từ file `test.prog` bằng `$readmemb`.

Trong mô phỏng tổng thể, `test.prog` phải nằm trong working directory khi chạy `vvp`. Vì vậy phần hướng dẫn chạy bên dưới copy file này vào thư mục `build/`.

### `control.v`

`control` nhận `opcode[5:0]` và sinh tín hiệu điều khiển cho Datapath.

Port output:

| Tín hiệu | Chức năng |
| --- | --- |
| `op[1:0]` | Chọn nhóm thao tác ALU/datapath. `01` dùng ALU, `10` dùng nhóm mvi/load/store theo thiết kế hiện tại. |
| `mread` | Cho phép đọc Data Memory. |
| `mwrite` | Cho phép ghi Data Memory. |
| `alusrc` | Chọn dữ liệu immediate thay vì kết quả ALU khi write-back. |
| `rdt` | Chọn format có 2 source/2 destination register, dùng cho nhóm ALU. |
| `mtr` | Memory-to-register, chọn dữ liệu từ Data Memory để ghi về thanh ghi. |
| `rwrite` | Cho phép ghi Register File. |
| `regprint` | Xuất trạng thái Register File và Data Memory khi gặp `hlt`. |

### `datapath.v`

`datapath` là nơi instruction được tách field và thực thi.

Các field chính được lấy từ `instr[31:0]`:

| Field | Bit | Ý nghĩa trong code |
| --- | --- | --- |
| `opcode` | `[31:26]` | Opcode gửi sang Control Unit và ALU control. |
| `rwdt1` | `[25:21]` | Địa chỉ thanh ghi ghi kết quả chính. |
| `rwdt2` | `[20:16]` | Địa chỉ thanh ghi ghi kết quả phụ khi `rdt = 1`. |
| `rsc2` | `[9:5]` | Source register A cho ALU khi `rdt = 1`. |
| `rsc1` | `[4:0]` | Source register B cho ALU hoặc source register khi store. |
| `imm` | `[7:0]` | Immediate 8-bit cho `mvi`. |
| `ddt` | `[7:0]` hoặc `[25:18]` | Địa chỉ Data Memory. Load dùng `[7:0]`, store dùng `[25:18]`. |

Luồng dữ liệu chính:

1. Register File đọc `out_data1` và `out_data2`.
2. ALU nhận `a = out_data2`, `b = out_data1`.
3. Data Memory nhận địa chỉ `ddt`.
4. Write-back chọn giữa `mem_data` và `kgf`.
5. Register File ghi `in_data1` vào `rwdt1`, `in_data2` vào `rwdt2`.

### `reg8.v`

`reg8` là Register File.

- 32 thanh ghi.
- Mỗi thanh ghi 8-bit.
- 2 cổng đọc: `address1`, `address2`.
- 2 cổng ghi: `rwdt1`, `rwdt2`.
- Ghi đồng bộ tại `posedge clk` khi `w_en = 1`.
- Đọc bất đồng bộ qua `assign out_data1 = reg_mem[address1]`.
- Khi `p_en = 1`, ghi toàn bộ 32 thanh ghi vào `reg_out.o`.

### `mem8.v`

`mem8` là Data Memory.

- 256 ô nhớ.
- Mỗi ô 8-bit.
- Nạp dữ liệu ban đầu từ `test.data`.
- Ghi đồng bộ tại `posedge clk` khi `w_en = 1`.
- Đọc bất đồng bộ khi `en = 1`.
- Khi `p_en = 1`, ghi toàn bộ 256 ô nhớ vào `data_out.o`.

### `alu8.v`

`alu8` là ALU 8-bit, nhận:

| Tín hiệu | Độ rộng | Ý nghĩa |
| --- | --- | --- |
| `a` | 8 bit | Toán hạng A |
| `b` | 8 bit | Toán hạng B |
| `opc` | 4 bit | Mã phép toán lấy từ 4 bit thấp của opcode |
| `op` | 2 bit | Nhóm thao tác, phép ALU chạy khi `op = 2'b01` |
| `out` | 8 bit | Kết quả chính |
| `out2` | 8 bit | Kết quả phụ, dùng cho nhân/chia |
| `carry` | 1 bit | Carry hoặc flag so sánh |

Các khối con trong ALU:

- `rd8`: cộng/trừ 8-bit bằng recursive doubling adder.
- `wtm8`: nhân 8-bit bằng Wallace Tree multiplier.
- `nrd8`: chia 8-bit bằng Non-Restoring division.
- `bs8`: dịch trái/dịch phải bằng barrel shifter.
- Các phép logic: not, and, or, nand, nor, xor, xnor.
- Các phép so sánh: greater, equal.

## Instruction Format

Instruction có độ rộng 32-bit. 6 bit cao nhất luôn là opcode.

### Format nhóm ALU

```text
31          26 25     21 20     16 15          10 9       5 4       0
+-------------+---------+---------+--------------+---------+---------+
| opcode[5:0] | dest1   | dest2   | reserved     | srcA    | srcB    |
+-------------+---------+---------+--------------+---------+---------+
```

Ý nghĩa:

- `dest1`: thanh ghi nhận `out`.
- `dest2`: thanh ghi nhận `out2`; hữu ích với `mul` và `div`.
- `srcA`: toán hạng A đưa vào ALU.
- `srcB`: toán hạng B đưa vào ALU.
- Với các phép chỉ có một kết quả như add/sub/logic/shift, `dest2` thường có thể để `0`.

Ví dụ:

```text
0100_0000_0010_0000_0000_0000_0010_0010
```

Lệnh trên là `add r1, r1, r2`:

- `opcode = 010000`: add.
- `dest1 = 00001`: ghi kết quả vào `reg[1]`.
- `srcA = 00001`: đọc `reg[1]`.
- `srcB = 00010`: đọc `reg[2]`.

### Format `mvi`

```text
31          26 25     21 20                         8 7       0
+-------------+---------+----------------------------+---------+
| 100000      | dest    | unused                     | imm8    |
+-------------+---------+----------------------------+---------+
```

Chức năng: `dest = imm8`.

### Format `load`

```text
31          26 25     21 20                         8 7       0
+-------------+---------+----------------------------+---------+
| 100010      | dest    | unused                     | addr8   |
+-------------+---------+----------------------------+---------+
```

Chức năng: `dest = data_mem[addr8]`.

### Format `store`

```text
31          26 25       18 17                    5 4       0
+-------------+-----------+-----------------------+---------+
| 100011      | addr8     | unused                | src     |
+-------------+-----------+-----------------------+---------+
```

Chức năng: `data_mem[addr8] = reg[src]`.

### Format `hlt`

```text
31          26 25                                      0
+-------------+-----------------------------------------+
| 111111      | unused                                  |
+-------------+-----------------------------------------+
```

Chức năng: bật `regprint` để xuất trạng thái thanh ghi và bộ nhớ.

## Instruction Set

### Nhóm non-ALU

| Opcode | Mnemonic | Mô tả | Ghi chú |
| --- | --- | --- | --- |
| `100000` | `mvi dest, imm8` | Gán immediate 8-bit vào thanh ghi | Dùng `alusrc = 1`. |
| `100001` | `mov dest, src` | Di chuyển dữ liệu giữa thanh ghi | Có opcode trong Control Unit; xem ghi chú kỹ thuật ở cuối README. |
| `100010` | `load dest, [addr]` | Đọc Data Memory vào thanh ghi | Dùng `mread = 1`, `mtr = 1`. |
| `100011` | `store [addr], src` | Ghi thanh ghi vào Data Memory | Dùng `mwrite = 1`. |
| `111111` | `hlt` | Dừng chương trình mẫu và xuất debug file | Bật `regprint = 1`. |

### Nhóm ALU

Với nhóm ALU, opcode có dạng `01xxxx`. Bốn bit thấp `xxxx` được đưa vào `opc`.

| Opcode | `opc` | Mnemonic | Kết quả |
| --- | --- | --- | --- |
| `010000` | `0000` | `add dest, a, b` | `out = a + b`, `carry = carry_out` |
| `010001` | `0001` | `sub dest, a, b` | `out = a - b`, `carry = carry_out` |
| `010010` | `0010` | `mul destLow, destHigh, a, b` | `out = product[7:0]`, `out2 = product[15:8]` |
| `010011` | `0011` | `div quotient, remainder, a, b` | `out = quotient`, `out2 = remainder` |
| `010100` | `0100` | `shl dest, a, b` | `out = a << b[2:0]` |
| `010101` | `0101` | `shr dest, a, b` | `out = a >> b[2:0]` |
| `010110` | `0110` | `rol dest, a` | `out = {a[6:0], a[7]}` |
| `010111` | `0111` | `not dest, a` | `out = ~a` |
| `011000` | `1000` | `and dest, a, b` | `out = a & b` |
| `011001` | `1001` | `or dest, a, b` | `out = a | b` |
| `011010` | `1010` | `nand dest, a, b` | `out = ~(a & b)` |
| `011011` | `1011` | `nor dest, a, b` | `out = ~(a | b)` |
| `011100` | `1100` | `xor dest, a, b` | `out = a ^ b` |
| `011101` | `1101` | `xnor dest, a, b` | `out = ~(a ^ b)` |
| `011110` | `1110` | `greater a, b` | `carry = 1` nếu `a > b`, ngược lại `0` |
| `011111` | `1111` | `equal a, b` | `carry = 1` nếu `a == b`, ngược lại `0` |

## Bảng Tín Hiệu Điều Khiển

Bảng dưới mô tả các giá trị được sinh trong `control.v`.

| Lệnh | Opcode | `rdt` | `alusrc` | `mtr` | `rwrite` | `mread` | `mwrite` | `op` | `regprint` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `mvi` | `100000` | `0` | `1` | `0` | `1` | `0` | `0` | `10` | `0` |
| `mov` | `100001` | `0` | `0` | `0` | `1` | `0` | `0` | `10` | `0` |
| `load` | `100010` | `0` | `0` | `1` | `1` | `1` | `0` | `10` | `0` |
| `store` | `100011` | `0` | `0` | `0` | `0` | `0` | `1` | `10` | `0` |
| ALU | `01xxxx` | `1` | `0` | `0` | `1` | `0` | `0` | `01` | `0` |
| `hlt` | `111111` | `1` | `0` | `0` | `1` | `0` | `0` | `01` | `1` |

## Chương Trình Mẫu Trong `test.prog`

Chương trình mẫu thực hiện phép cộng 8 số trong Data Memory:

```text
load r1, [61]
load r2, [62]
add  r1, r1, r2
load r2, [63]
add  r1, r1, r2
load r2, [64]
add  r1, r1, r2
load r2, [65]
add  r1, r1, r2
load r2, [66]
add  r1, r1, r2
load r2, [67]
add  r1, r1, r2
load r2, [68]
add  r1, r1, r2
hlt
```

Dữ liệu trong `DataMemory/test.data` tại địa chỉ 61 đến 68:

| Địa chỉ | Binary | Decimal |
| --- | --- | --- |
| `61` | `00000101` | `5` |
| `62` | `00000101` | `5` |
| `63` | `00000101` | `5` |
| `64` | `00000101` | `5` |
| `65` | `00000101` | `5` |
| `66` | `00000101` | `5` |
| `67` | `00000101` | `5` |
| `68` | `00000111` | `7` |

Kết quả kỳ vọng:

```text
5 + 5 + 5 + 5 + 5 + 5 + 5 + 7 = 42
```

Sau mô phỏng, file `reg_out.o` ghi:

```text
reg_mem[1] = 00101010
```

`00101010` là `42` trong hệ thập phân.

## Cài Đặt Công Cụ

Repo được kiểm thử bằng Icarus Verilog.

Trên macOS:

```sh
brew install icarus-verilog
```

Kiểm tra:

```sh
iverilog -V
vvp -V
```

## Chạy Mô Phỏng Toàn Bộ CPU

Do các module dùng `$readmemb("test.prog")` và `$readmemb("test.data")`, khi chạy `vvp` cần đặt hai file dữ liệu này trong cùng working directory với simulator. Cách đơn giản là build và chạy trong thư mục `build/`.

```sh
mkdir -p build

cp InstructionRegister/test.prog build/test.prog
cp DataMemory/test.data build/test.data

iverilog -o build/main8_sim \
  -IProgramCounter \
  -IInstructionRegister \
  -IDataMemory \
  -IGPIOs \
  -IALU \
  -I"ALU/8 bit recursive dabling adder" \
  -I"ALU/8 bit wallace tree multiplication" \
  -I"ALU/8 bit non restoring division" \
  -I"ALU/8 bit barrel shifter" \
  main8_tb.v

cd build
vvp main8_sim
```

Sau khi chạy, thư mục `build/` sẽ có các file:

| File | Ý nghĩa |
| --- | --- |
| `main8_sim` | File mô phỏng do `iverilog` sinh ra. |
| `main.vcd` | Waveform để xem bằng GTKWave hoặc công cụ tương tự. |
| `reg_out.o` | Trạng thái 32 thanh ghi khi `hlt`. |
| `data_out.o` | Trạng thái 256 ô Data Memory khi `hlt`. |

Xem nhanh kết quả thanh ghi:

```sh
sed -n '1,40p' reg_out.o
```

Kết quả quan trọng cần thấy:

```text
reg_mem[1] = 00101010
```

## Chạy Testbench Từng Module

### Program Counter

```sh
cd ProgramCounter
iverilog -o pc6_sim pc6_tb.v
vvp pc6_sim
```

### Instruction Memory

```sh
cd InstructionRegister
iverilog -o ir8_sim ir8_tb.v
vvp ir8_sim
```

### Data Memory

```sh
cd DataMemory
iverilog -o mem8_sim mem8_tb.v
vvp mem8_sim
```

### Register File

```sh
cd GPIOs
iverilog -o reg8_sim reg8_tb.v
vvp reg8_sim
```

### Control Unit

```sh
iverilog -o build/control_sim control_tb.v
vvp build/control_sim
```

### ALU

```sh
iverilog -o build/alu8_sim \
  -IALU \
  -I"ALU/8 bit recursive dabling adder" \
  -I"ALU/8 bit wallace tree multiplication" \
  -I"ALU/8 bit non restoring division" \
  -I"ALU/8 bit barrel shifter" \
  ALU/alu8_tb.v

vvp build/alu8_sim
```

## Ghi Chú Khi Compile

Khi bật `-Wall`, Icarus Verilog có thể báo một số warning nhưng mô phỏng vẫn chạy:

- `implicit definition of wire 'f'`, `c`, `c1`: một số wire phụ trong ALU chưa khai báo tường minh.
- `@* is sensitive to all 256 words in array 'data_mem'`: do `mem8.v` xuất toàn bộ RAM trong khối debug.

Các warning này không chặn mô phỏng chương trình mẫu. Nếu phát triển tiếp, nên khai báo tường minh các wire phụ và chuyển các khối `$readmemb`/debug dump về cấu trúc rõ ràng hơn.

## File Đầu Vào Và Đầu Ra

### `InstructionRegister/test.prog`

- Chứa tối đa 64 instruction.
- Mỗi dòng là một instruction 32-bit ở dạng binary.
- Dấu gạch dưới `_` chỉ dùng để dễ đọc.
- Dòng đầu tiên được load vào `ir_mem[0]`.

### `DataMemory/test.data`

- Chứa 256 dòng dữ liệu.
- Mỗi dòng là một giá trị 8-bit.
- Dòng đầu tiên được load vào `data_mem[0]`.

### `reg_out.o`

- Sinh khi `regprint = 1`.
- Ghi toàn bộ `reg_mem[0]` đến `reg_mem[31]`.
- Dùng để kiểm tra kết quả cuối của CPU.

### `data_out.o`

- Sinh khi `regprint = 1`.
- Ghi toàn bộ `data_mem[0]` đến `data_mem[255]`.
- Dùng để kiểm tra load/store và trạng thái RAM.

### `main.vcd` hoặc `dump.vcd`

- File waveform.
- Có thể mở bằng GTKWave:

```sh
gtkwave build/main.vcd
```

## Ghi Chú Kỹ Thuật

- CPU hiện tại là mô hình mô phỏng RTL đơn giản, chưa phải một core pipeline hoàn chỉnh.
- Program Counter có độ rộng 6-bit nên chương trình tối đa 64 instruction.
- Data Memory có địa chỉ 8-bit nên truy cập tối đa 256 ô nhớ.
- Register File dùng 5-bit address nên có 32 thanh ghi.
- Với `mul`, kết quả 16-bit được tách thành `out` thấp 8-bit và `out2` cao 8-bit.
- Với `div`, `out` là thương, `out2` là số dư.
- Opcode `mov` đã có trong `control.v`, nhưng Datapath hiện tại chưa có đường mux rõ ràng để đưa trực tiếp dữ liệu thanh ghi nguồn về write-back cho đúng nghĩa `mov dest, src`. Nếu muốn dùng `mov` trong chương trình thực tế, nên bổ sung nhánh write-back từ `out_data1` hoặc điều chỉnh ALU/datapath.

## Tóm Tắt Kết Quả Đồ Án

Đồ án đã hiện thực được một CPU 8-bit có đầy đủ các khối cơ bản:

- Fetch instruction bằng Program Counter và Instruction Memory.
- Decode opcode bằng Control Unit.
- Execute bằng ALU 8-bit có cộng, trừ, nhân, chia, dịch bit, xoay bit, logic và so sánh.
- Truy cập Data Memory bằng load/store.
- Ghi kết quả về Register File.
- Mô phỏng chương trình mẫu tính tổng 8 số trong RAM và thu được kết quả `42`.
