/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

 #include <stdint.h>
 #include <stdbool.h>
 
 #define MEM_TOTAL 0x3800 /* 14 KiB */
 
 // a pointer to this is a null pointer, but the compiler does not
 // know that because "sram" is a linker symbol from sections.lds.
 extern uint32_t sram;
 
 #define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
 #define reg_uart_data (*(volatile uint32_t*)0x02000008)
 #define reg_leds (*(volatile uint32_t*)0x02000000)
 
 // --------------------------------------------------------
 
 void putchar(char c)
 {
	 if (c == '\n')
		 putchar('\r');
	 reg_uart_data = c;
 }
 
 void print(const char *p)
 {
	 while (*p)
		 putchar(*(p++));
 }
 
 void print_hex(uint32_t v, int digits)
 {
	 for (int i = 7; i >= 0; i--) {
		 char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		 if (c == '0' && i >= digits) continue;
		 putchar(c);
		 digits = i;
	 }
 }
 
 void print_dec(uint32_t v)
 {
	 if (v >= 1000) {
		 print(">=1000");
		 return;
	 }
 
	 if      (v >= 900) { putchar('9'); v -= 900; }
	 else if (v >= 800) { putchar('8'); v -= 800; }
	 else if (v >= 700) { putchar('7'); v -= 700; }
	 else if (v >= 600) { putchar('6'); v -= 600; }
	 else if (v >= 500) { putchar('5'); v -= 500; }
	 else if (v >= 400) { putchar('4'); v -= 400; }
	 else if (v >= 300) { putchar('3'); v -= 300; }
	 else if (v >= 200) { putchar('2'); v -= 200; }
	 else if (v >= 100) { putchar('1'); v -= 100; }
 
	 if      (v >= 90) { putchar('9'); v -= 90; }
	 else if (v >= 80) { putchar('8'); v -= 80; }
	 else if (v >= 70) { putchar('7'); v -= 70; }
	 else if (v >= 60) { putchar('6'); v -= 60; }
	 else if (v >= 50) { putchar('5'); v -= 50; }
	 else if (v >= 40) { putchar('4'); v -= 40; }
	 else if (v >= 30) { putchar('3'); v -= 30; }
	 else if (v >= 20) { putchar('2'); v -= 20; }
	 else if (v >= 10) { putchar('1'); v -= 10; }
 
	 if      (v >= 9) { putchar('9'); v -= 9; }
	 else if (v >= 8) { putchar('8'); v -= 8; }
	 else if (v >= 7) { putchar('7'); v -= 7; }
	 else if (v >= 6) { putchar('6'); v -= 6; }
	 else if (v >= 5) { putchar('5'); v -= 5; }
	 else if (v >= 4) { putchar('4'); v -= 4; }
	 else if (v >= 3) { putchar('3'); v -= 3; }
	 else if (v >= 2) { putchar('2'); v -= 2; }
	 else if (v >= 1) { putchar('1'); v -= 1; }
	 else putchar('0');
 }
 
 char getchar_prompt(char *prompt)
 {
	 int32_t c = -1;
 
	 uint32_t cycles_begin, cycles_now, cycles;
	 __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
 
	 reg_leds = ~0;
 
	 if (prompt)
		 print(prompt);
 
	 while (c == -1) {
		 __asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		 cycles = cycles_now - cycles_begin;
		 if (cycles > 12000000) {
			 if (prompt)
				 print(prompt);
			 cycles_begin = cycles_now;
			 reg_leds = ~reg_leds;
		 }
		 c = reg_uart_data;
	 }
 
	 reg_leds = 0;
	 return c;
 }
 
 char getchar()
 {
	 return getchar_prompt(0);
 }

 uint32_t xorshift32(uint32_t *state)
 {
	 /* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	 uint32_t x = *state;
	 x ^= x << 13;
	 x ^= x >> 17;
	 x ^= x << 5;
	 *state = x;
 
	 return x;
 }
 
 // --------------------------------------------------------
 
 uint32_t cmd_benchmark(bool verbose, uint32_t *instns_p)
 {
	 uint8_t data[256];
	 uint32_t *words = (void*)data;
 
	 uint32_t x32 = 314159265;
 
	 uint32_t cycles_begin, cycles_end;
	 uint32_t instns_begin, instns_end;
	 __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	 __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
 
	 for (int i = 0; i < 20; i++)
	 {
		 for (int k = 0; k < 256; k++)
		 {
			 x32 ^= x32 << 13;
			 x32 ^= x32 >> 17;
			 x32 ^= x32 << 5;
			 data[k] = x32;
		 }
 
		 for (int k = 0, p = 0; k < 256; k++)
		 {
			 if (data[k])
				 data[p++] = k;
		 }
 
		 for (int k = 0, p = 0; k < 64; k++)
		 {
			 x32 = x32 ^ words[k];
		 }
	 }
 
	 __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	 __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
 
	 if (verbose)
	 {
		 print("Cycles: 0x");
		 print_hex(cycles_end - cycles_begin, 8);
		 putchar('\n');
 
		 print("Instns: 0x");
		 print_hex(instns_end - instns_begin, 8);
		 putchar('\n');
 
		 print("Chksum: 0x");
		 print_hex(x32, 8);
		 putchar('\n');
	 }
 
	 if (instns_p)
		 *instns_p = instns_end - instns_begin;
 
	 return cycles_end - cycles_begin;
 }
 
 // --------------------------------------------------------
 
 void cmd_echo()
 {
	 print("Return to menu by sending '!'\n\n");
	 char c;
	 while ((c = getchar()) != '!')
		 putchar(c);
 }
 
 // --------------------------------------------------------
 
 void main()
 {
	 reg_leds = 31;
	 reg_uart_clkdiv = 104;
	 print("Booting..\n");
 
	 reg_leds = 127;
	 while (getchar_prompt("Press ENTER to continue..\n") != '\r') { /* wait */ }
 
	 print("\n");
	 print("  ____  _          ____         ____\n");
	 print(" |  _ \\(_) ___ ___/ ___|  ___  / ___|\n");
	 print(" | |_) | |/ __/ _ \\___ \\ / _ \\| |\n");
	 print(" |  __/| | (_| (_) |__) | (_) | |___\n");
	 print(" |_|   |_|\\___\\___/____/ \\___/ \\____|\n");
	 print("\n");
 
	 print("Total memory: ");
	 print_dec(MEM_TOTAL / 1024);
	 print(" KiB\n");
	 print("\n");
 
	 while (1)
	 {
		 print("\n");
 
		 print("Select an action:\n");
		 print("\n");
		 print("   [1] Run simplistic benchmark\n");
		 print("   [2] Echo UART\n");
		 print("\n");
 
		 for (int rep = 10; rep > 0; rep--)
		 {
			 print("Command> ");
			 char cmd = getchar();
			 if (cmd > 32 && cmd < 127)
				 putchar(cmd);
			 print("\n");
 
			 switch (cmd)
			 {
			 case '1':
				 cmd_benchmark(true, 0);
				 break;
			 case '2':
				 cmd_echo();
				 break;
			 default:
				 continue;
			 }
 
			 break;
		 }
	 }
 }
 