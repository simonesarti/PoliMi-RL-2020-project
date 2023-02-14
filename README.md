# PoliMi-RL-2020-project

## General Description
The specification of the Final Proof (Logical Networks Project) 2019 is inspired by the coding method with low power dissipation called "Working Zone". The Working Zone encoding method is a method designed for the Address Bus that is used to transforming the value of an address when it is transmitted, if it belongs to certain intervals (known as working-zones). A working zone is defined as an interval of addresses of fixed size (Dwz) starting from a base address. Within the coding scheme, multiple working-zones (Nwz) may exist. The modified coding scheme to be implemented is as follows:
* if the address to be transmitted (ADDR) does not belong to any working-zone, it is transmitted as is, and an additional bit to the addressing bits (WZ_BIT) is set to 0. In practice given ADDR, WZ_BIT=0 will be transmitted concatenated to ADDR (WZ_BIT & ADDR, where & is the concatenation symbol);
* if the address to be transmitted (ADDR) belongs to a Working Zone, the additional bit additional bit WZ_BIT is set to 1, while the address bits are divided into 2 sub representative fields:
    * The number of the working-zone to which the address belongs WZ_NUM, which will be encoded in binary
    * The offset from the base address of the working zone WZ_OFFSET, encoded as a one-hot (i.e. the value to be represented is equivalent to the one-hot bit of the encoding). 
In practice given ADDR, WZ_BIT=1 concatenated to WZ_NUM and WZ_OFFSET ( WZ_BIT & WZ_NUM & WZ_OFFSET, where & is the concatenation symbol)

In the version to be implemented, the number of bits to be considered for the address to be encoded is
7. This defines those from 0 to 127 as valid addresses. The number of working-zones is 8
(Nwz=8) while the size of the working-zone is 4 addresses including the base address (Dwz=4).
This implies that the encoded address will consist of 8 bits: 1 bit for WZ_BIT + 7 bits
for ADDR, or 1 bit for WZ_BIT, 3 bits to encode in binary which of the 8 working
zones the address belongs to, and 4 bits to encode one hot the offset value of ADDR with respect
to the base address.
The module to be implemented will read the address to be encoded and the 8 base addresses of the
working-zones and shall produce the appropriately encoded address.

## Data
The data each of size 8 bits is stored in a memory with addressing to the Byte starting at position 0. Even the address that is by specification 7 bits is stored on 8 bits. The value of the eighth bit will always be zero.
- Memory locations 0 to 7 are used to store the eight base addresses of the working zones:
    - 0 - WZ Base Address 0
    - 1 - WZ Base Address 1
    - ...
    - 7 - Base address WZ 7
    - Memory location 8 will contain the value (address) to be encoded (ADDR);
    - Memory location 9 is to be used to eventually write the value encoded according to the previous rules.


## Additional notes on the specification
1. In coding 1 hot consider bit 0 as the least significant bit. In practice:
    * WZ_OFFSET = 0 is encoded one hot as 0001;
    * WZ_OFFSET = 1 is coded one hot as 0010;
    * WZ_OFFSET = 2 is coded one hot as 0100;
    * WZ_OFFSET = 3 is coded one hot as 1000;
2. Taking the specification again, the encoded value will be composed as follows:
    * Bit 7: value of the single bit of WZ_BIT;
    * Bits 6-4: binary coded value of WZ_NUM;
    * Bits 3-0: one-hot encoded value of WZ_OFFSET
3. If necessary, consider that the base addresses of the working-zones will never change within the same execution;
4. The module will start processing when an input START signal is set to 1. The START signal will remain high until the DONE signal is brought high; At the end of the computation (and once the result has been written to memory) the module to be designed must raise (bring to 1) the DONE signal that notifies the end of the processing. The DONE signal must remain high until the START signal signal is not reset to 0. A new start signal cannot be given until DONE has not been reset to zero. If the START signal is raised at this point, the module must restart with the encoding phase.


## Examples:
The following sequence of numbers shows an example of the contents of the memory at the end
of a processing operation. The values represented here in decimal, are stored in
memory with the equivalent unsigned 8-bit binary encoding.

CASE 1 WITH VALUE NOT PRESENT IN ANY WORKING-ZONE
| Address | Memory value | Comment |
|---|---|---|
| 0 | 4 | Base Address WZ 0 |
| 1 | 13 | Base Address WZ 1 |
| 2 | 22 | Base Address WZ 2 |
| 3 | 31 | Base Address WZ 3 |
| 4 | 37 | Base Address WZ 4 |
| 5 | 45 | Base Address WZ 5 |
| 6 | 77 | Base Address WZ 6 |
| 7 | 91 | Base Address WZ 7 |
| 8 | 42 | ADDR to be encoded |
| 9 | 42 | Coded value in OUTPUT |

CASE 2 WITH VALUE IN A WORKING-ZONE
| Address | Memory value | Comment |
|---|---|---|
| 0 | 4 | Base Address WZ 0 |
| 1 | 13 | Base Address WZ 1 |
| 2 | 22 | Base Address WZ 2 |
| 3 | 31 | Base Address WZ 3 |
| 4 | 37 | Base Address WZ 4 |
| 5 | 45 | Base Address WZ 5 |
| 6 | 77 | Base Address WZ 6 |
| 7 | 91 | Base Address WZ 7 |
| 8 | 42 | ADDR to be encoded |
| 9 | 180 | Coded value in OUTPUT (1 - 011 - 0100) |

# Component Inteface

```
entity project_reti_logiche is
port (
  i_clk : in std_logic;
  i_start : in std_logic;
  i_rst : in std_logic;
  i_data : in std_logic_vector(7 downto 0);
  o_address : out std_logic_vector(15 downto 0);
  o_done : out std_logic;
  o_en : out std_logic;
  o_we : out std_logic;
  o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;
```

In particular:
- i_clk is the input CLOCK signal generated by the TestBench;
- i_start is the START signal generated by the Test Bench;
- i_rst is the RESET signal which initialises the machine ready to receive the first
START signal;
- i_data is the signal (vector) that arrives from memory following a request to
read;
- o_address is the output signal (vector) that sends the address to the memory;
- o_done is the output signal that communicates the end of processing and the output data
written to memory;
- o_en is the ENABLE signal that must be sent to the memory in order to communicate
(both read and write);
- o_we is the WRITE ENABLE signal that must be sent to the memory (=1) to be able to
write to it. To read from memory it must be 0;
- o_data is the output signal (vector) from the component to the memory.
