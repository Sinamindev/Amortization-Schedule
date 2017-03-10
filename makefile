runme: amortization-schedule-driver.cpp payment_calculator.cpp amortization-schedule.o
	gcc amortization-schedule-driver.cpp payment_calculator.cpp amortization-schedule.o -o runme

amortization-schedule.o: amortization-schedule.asm 
	nasm -f elf64 amortization-schedule.asm -o amortization-schedule.o
